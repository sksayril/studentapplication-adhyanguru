import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/skeleton_loader.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  String _selectedPlanType = 'monthly';
  
  // Active subscription state
  Map<String, dynamic>? _activeSubscription;
  bool _isLoadingSubscription = true;
  
  // Payment state
  late Razorpay _razorpay;
  String? _currentOrderId;
  String? _currentPlanId;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final newPlanType = _tabController.index == 0 ? 'monthly' : 'yearly';
        if (newPlanType != _selectedPlanType) {
          setState(() {
            _selectedPlanType = newPlanType;
          });
          _loadSubscriptionPlans();
        }
      }
    });
    
    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    _loadActiveSubscription();
    _loadSubscriptionPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadActiveSubscription() async {
    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingSubscription = false;
        });
        return;
      }

      final response = await ApiService.getActiveSubscription(token);
      
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final hasActive = data['hasActiveSubscription'] as bool? ?? false;
          
          setState(() {
            _activeSubscription = hasActive ? (data['subscription'] as Map<String, dynamic>?) : null;
            _isLoadingSubscription = false;
          });
        } else {
          setState(() {
            _activeSubscription = null;
            _isLoadingSubscription = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeSubscription = null;
          _isLoadingSubscription = false;
        });
      }
    }
  }

  Future<void> _loadSubscriptionPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login to view subscription plans';
        });
        return;
      }

      final response = await ApiService.getSubscriptionPlans(token, planType: _selectedPlanType);
      
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          final plans = data['plans'] as List? ?? [];
          
          setState(() {
            _plans = plans.map((p) => p as Map<String, dynamic>).toList();
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response['message'] ?? 'Failed to load subscription plans';
            _plans = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading subscription plans: ${e.toString()}';
          _plans = [];
        });
      }
    }
  }

  Future<void> _handleSubscribe(Map<String, dynamic> plan) async {
    final planId = plan['_id'] as String?;
    if (planId == null || planId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid plan selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show coupon code dialog
    final couponCode = await _showCouponDialog();
    if (couponCode == null) {
      return; // User cancelled dialog
    }
    // couponCode will be empty string if skipped, or contain the code if entered

    setState(() {
      _isProcessingPayment = true;
      _currentPlanId = planId;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isProcessingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please login to continue'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create order
      final orderResponse = await ApiService.createSubscriptionOrder(
        token,
        planId: planId,
        couponCode: couponCode.isEmpty ? null : couponCode,
      );

      if (mounted) {
        if (orderResponse['success'] == true && orderResponse['data'] != null) {
          final orderData = orderResponse['data'] as Map<String, dynamic>;
          final orderId = orderData['orderId'] as String?;
          final amount = orderData['amount'] as num? ?? 0;
          final keyId = orderData['keyId'] as String?;

          if (orderId != null && keyId != null) {
            _currentOrderId = orderId;

            // Open Razorpay checkout
            // IMPORTANT: Include order_id in options to get signature in response
            final options = {
              'key': keyId,
              'amount': (amount * 100).toInt(), // Convert to paise
              'name': plan['name'] as String? ?? 'Subscription',
              'description': plan['description'] as String? ?? '',
              'order_id': orderId, // Include order_id to get signature in response
              'prefill': {
                'contact': '',
                'email': '',
              },
              'external': {
                'wallets': ['paytm']
              }
            };

            _razorpay.open(options);
          } else {
            setState(() {
              _isProcessingPayment = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(orderResponse['message'] ?? 'Failed to create order'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          setState(() {
            _isProcessingPayment = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderResponse['message'] ?? 'Failed to create order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showCouponDialog() async {
    final couponController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Apply Coupon Code',
          style: AppTextStyles.heading2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter coupon code (optional)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: couponController,
              decoration: InputDecoration(
                hintText: 'Enter coupon code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, ''); // Return empty string for skip
            },
            child: Text(
              'Skip',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final couponCode = couponController.text.trim();
              Navigator.pop(context, couponCode); // Return coupon code or empty string
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return result; // Returns empty string if skipped, coupon code if entered, or null if cancelled
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentOrderId == null || _currentPlanId == null) {
      setState(() {
        _isProcessingPayment = false;
      });
      return;
    }

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isProcessingPayment = false;
        });
        return;
      }

      // Extract payment details with validation
      final paymentId = response.paymentId;
      var signature = response.signature;
      
      // Debug logging - print full response structure
      print('=== Payment Success Response ===');
      print('Payment ID: $paymentId');
      print('Order ID: $_currentOrderId');
      print('Signature (from response.signature): ${signature != null ? (signature.length > 20 ? "${signature.substring(0, 20)}..." : signature) : "NULL"}');
      
      // Try to access signature from response data if available
      // When order_id is included in Razorpay options, signature should be available
      // Sometimes Razorpay provides signature in response.data or other fields
      if (signature == null || signature.isEmpty) {
        try {
          // Check if response has a data property that might contain signature
          // Note: PaymentSuccessResponse may have different structure in different SDK versions
          final responseString = response.toString();
          print('Full response string: $responseString');
          
          // Try to access via reflection/dynamic access if available
          try {
            final responseData = (response as dynamic).data;
            if (responseData != null) {
              print('Response data available: ${responseData.toString()}');
              // Try common signature field names
              if (responseData is Map) {
                final dataMap = responseData as Map;
                signature = dataMap['razorpay_signature'] as String? ?? 
                          dataMap['signature'] as String? ??
                          dataMap['razorpaySignature'] as String?;
                if (signature != null && signature.isNotEmpty) {
                  print('Found signature in response.data: ${signature.length > 20 ? "${signature.substring(0, 20)}..." : signature}');
                }
              }
            }
          } catch (e) {
            print('Response.data not accessible: $e');
          }
          
          // Also try accessing order_id from response to verify
          try {
            final responseOrderId = (response as dynamic).orderId;
            if (responseOrderId != null) {
              print('Response Order ID: $responseOrderId');
            }
          } catch (e) {
            print('Could not access orderId from response: $e');
          }
        } catch (e) {
          print('Error accessing response data: $e');
        }
      }
      
      print('Final Signature: ${signature != null ? (signature.length > 20 ? "${signature.substring(0, 20)}..." : signature) : "NULL"}');
      print('===============================');
      
      // Validate required fields
      if (paymentId == null || paymentId.isEmpty) {
        setState(() {
          _isProcessingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment ID is missing. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Note: Razorpay Flutter SDK doesn't provide signature in PaymentSuccessResponse
      // The backend should verify payment using order_id and payment_id when signature is missing
      // We'll pass null if signature is not available - backend should handle this
      if (signature != null && signature.isEmpty) {
        signature = null; // Convert empty string to null
      }
      
      if (signature == null) {
        print('WARNING: Razorpay signature is not available. Backend should verify using order_id and payment_id.');
      }

      // Verify payment
      // Note: If signature is null/empty, backend should verify using order_id and payment_id via Razorpay API
      final verifyResponse = await ApiService.verifyPayment(
        token,
        razorpayOrderId: _currentOrderId!,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature, // Can be null if not provided by SDK
      );

      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });

        if (verifyResponse['success'] == true) {
          // Reload active subscription
          await _loadActiveSubscription();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment successful! Subscription activated.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          // Check if error is due to missing signature
          final errorMessage = verifyResponse['message'] ?? 'Payment verification failed';
          final isSignatureError = errorMessage.toLowerCase().contains('signature');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isSignatureError 
                  ? 'Payment verification issue. Your payment was successful. Please contact support with Payment ID: $paymentId'
                  : errorMessage,
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Contact Support',
                textColor: Colors.white,
                onPressed: () {
                  // You can add navigation to support/help screen here
                },
              ),
            ),
          );
          
          // Log the issue for debugging
          print('=== Payment Verification Issue ===');
          print('Payment ID: $paymentId');
          print('Order ID: $_currentOrderId');
          print('Error: $errorMessage');
          print('Note: Razorpay Flutter SDK did not provide signature. Backend needs to verify using order_id and payment_id.');
          print('==================================');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? 'Unknown error'}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoadingSubscription)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_activeSubscription != null)
              _buildActiveSubscriptionCard(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null && _plans.isEmpty
                      ? _buildErrorState()
                      : _plans.isEmpty
                          ? _buildEmptyState()
                          : _buildPlansList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard() {
    final subscription = _activeSubscription!;
    final planId = subscription['planId'];
    final planName = planId is Map ? planId['name'] as String? : 'Active Plan';
    final status = subscription['status'] as String? ?? 'active';
    final startDate = subscription['startDate'] as String?;
    final endDate = subscription['endDate'] as String?;
    final daysRemaining = subscription['daysRemaining'] as int?;
    final isExpired = subscription['isExpired'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Active Subscription',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            planName ?? 'Premium Plan',
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          if (daysRemaining != null && !isExpired) ...[
            const SizedBox(height: 8),
            Text(
              '$daysRemaining days remaining',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
          if (startDate != null && endDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Valid until: ${_formatDate(endDate)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Subscription Plans',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _loadActiveSubscription();
              _loadSubscriptionPlans();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
          fontSize: 15,
        ),
        tabs: const [
          Tab(text: 'Monthly'),
          Tab(text: 'Yearly'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SkeletonLoader(
          width: double.infinity,
          height: 200,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 16),
        SkeletonLoader(
          width: double.infinity,
          height: 200,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 16),
        SkeletonLoader(
          width: double.infinity,
          height: 200,
          borderRadius: BorderRadius.circular(16),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Plans',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to fetch subscription plans',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSubscriptionPlans,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Plans Available',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No subscription plans available for ${_selectedPlanType} plans',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadActiveSubscription();
        await _loadSubscriptionPlans();
      },
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          ..._plans.map((plan) => _buildPlanCard(plan)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final name = plan['name'] as String? ?? 'Subscription Plan';
    final description = plan['description'] as String? ?? '';
    final price = plan['price'] as num? ?? 0;
    final originalPrice = plan['originalPrice'] as num?;
    final discountPercentage = plan['discountPercentage'] as num?;
    final features = plan['features'] as List? ?? [];
    final isPopular = plan['isPopular'] as bool? ?? false;
    final planType = plan['planType'] as String? ?? _selectedPlanType;
    final planId = plan['_id'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name
                Text(
                  name,
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 24),
                // Price section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/${planType == 'monthly' ? 'month' : 'year'}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                // Original price and discount
                if (originalPrice != null && originalPrice > price) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '₹${originalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 14,
                        ),
                      ),
                      if (discountPercentage != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${discountPercentage.toStringAsFixed(0)}% OFF',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                // Features
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    'Features:',
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...features.asMap().entries.map((entry) {
                    final index = entry.key;
                    final feature = entry.value;
                    final featureText = feature.toString();
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < features.length - 1 ? 14 : 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              featureText,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                const SizedBox(height: 28),
                // Subscribe button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment || planId == null
                        ? null
                        : () => _handleSubscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    child: _isProcessingPayment
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Subscribe Now',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
