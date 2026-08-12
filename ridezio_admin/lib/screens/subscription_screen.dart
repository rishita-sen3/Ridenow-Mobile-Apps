import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../models/plan.dart';

final subscriptionProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getSubscriptionDetails();
});

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isProcessing = false;

  Future<void> _purchasePlan(Plan plan, String duration) async {
    setState(() => _isProcessing = true);
    try {
      final res = await ref.read(apiServiceProvider).purchaseSubscription(plan.id, duration);
      final paymentUrl = res['payment_url'];
      final orderId = res['order_id'];

      final uri = Uri.parse(paymentUrl);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Scan to Pay', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: QrImageView(
                      data: paymentUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Scan this QR with any UPI app to pay.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link directly.')));
                      }
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open Payment Link'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                        await ref.read(apiServiceProvider).verifySubscription(orderId);
                        if (ctx.mounted) Navigator.pop(ctx); // Close loader
                        if (ctx.mounted) {
                          Navigator.pop(ctx); // Close QR dialog
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Subscription activated successfully!'), backgroundColor: Colors.green));
                          ref.refresh(subscriptionProvider);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          Navigator.pop(ctx); // close loader
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Payment not completed yet: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('I Have Paid', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel / Close', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          }
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showVerifyDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Payment'),
        content: const Text('Once you have completed the payment in your browser, tap "I Have Paid" to activate your subscription.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel / Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(apiServiceProvider).verifySubscription(orderId);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription activated successfully!'), backgroundColor: Colors.green));
                  ref.refresh(subscriptionProvider);
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('I Have Paid'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscription(Map<String, dynamic> data) {
    final status = data['shop_subscription_status'] ?? 'inactive';
    final endsAt = data['shop_subscription_ends_at'];
    final activeSub = data['active_subscription'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: status == 'active' ? [Colors.green.shade700, Colors.green.shade400] : [Colors.red.shade700, Colors.red.shade400]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: (status == 'active' ? Colors.green : Colors.red).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Icon(status == 'active' ? Icons.check_circle : Icons.warning, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status == 'active' ? 'Active Subscription' : 'No Active Subscription', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (status == 'active' && activeSub != null) ...[
                  const SizedBox(height: 4),
                  Text('Plan: ${activeSub['plan']['name']}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('Valid Until: $endsAt', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ] else if (endsAt != null) ...[
                  const SizedBox(height: 4),
                  Text('Expired On: $endsAt', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: plan.isFeatured ? Colors.amber : Colors.grey.shade200, width: plan.isFeatured ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          if (plan.isFeatured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
              child: const Text('RECOMMENDED', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(plan.description, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monthly', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text('₹${plan.monthlyPrice}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isProcessing ? null : () => _purchasePlan(plan, 'monthly'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Buy Monthly'),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Yearly (Save ~20%)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          Text('₹${plan.yearlyPrice}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : () => _purchasePlan(plan, 'yearly'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Buy Yearly', style: TextStyle(color: Colors.white)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
                _buildFeatureRow('Up to ${plan.maxVehicles} Vehicles'),
                _buildFeatureRow('Up to ${plan.maxShops} Shops'),
                if (plan.features.isNotEmpty)
                  ...plan.features.map((f) => _buildFeatureRow(f.toString())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(feature, style: const TextStyle(fontSize: 15, color: Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Subscriptions (v4)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final rawPlans = data['plans'] as List<dynamic>;
          final plans = rawPlans.map((p) => Plan.fromJson(p)).toList();

          return Stack(
            children: [
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildActiveSubscription(data),
                  const SizedBox(height: 32),
                  const Text('Upgrade Your Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  ...plans.map((p) => _buildPlanCard(p)),
                ],
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
            ],
          );
        },
      ),
    );
  }
}
