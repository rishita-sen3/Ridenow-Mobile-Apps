import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../models/premium_addon.dart';

final premiumProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getPremiumAddons();
});

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isProcessing = false;

  Future<void> _purchaseAddon(PremiumAddon addon) async {
    setState(() => _isProcessing = true);
    try {
      final res = await ref.read(apiServiceProvider).purchasePremiumAddon(addon.id);
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
                        await ref.read(apiServiceProvider).verifyPremiumAddon(orderId);
                        if (ctx.mounted) Navigator.pop(ctx); // Close loader
                        if (ctx.mounted) {
                          Navigator.pop(ctx); // Close QR dialog
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Premium Add-on activated successfully!'), backgroundColor: Colors.green));
                          ref.refresh(premiumProvider);
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
        content: const Text('Once you have completed the payment in your browser, tap "I Have Paid" to activate your Premium Add-on.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel / Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(apiServiceProvider).verifyPremiumAddon(orderId);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premium Add-on activated successfully!'), backgroundColor: Colors.green));
                  ref.refresh(premiumProvider);
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

  Widget _buildActiveAddonCard(ShopPremiumAddon activeAddon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.star, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activeAddon.addon?.name ?? 'Premium Addon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Valid Until: ${activeAddon.validUntil}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
            child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonCard(PremiumAddon addon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(addon.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('Duration: ${addon.durationDays} Days', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.auto_awesome, color: Colors.purple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(addon.description, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('₹${addon.price}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _purchaseAddon(addon),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Purchase Now', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Premium Upgrades (v4)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final rawAddons = data['addons'] as List<dynamic>;
          final rawActive = data['active_addons'] as List<dynamic>;
          
          final addons = rawAddons.map((a) => PremiumAddon.fromJson(a)).toList();
          final activeAddons = rawActive.map((a) => ShopPremiumAddon.fromJson(a)).toList();

          return Stack(
            children: [
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (activeAddons.isNotEmpty) ...[
                    const Text('Active Add-ons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...activeAddons.map((a) => _buildActiveAddonCard(a)),
                    const SizedBox(height: 24),
                  ],
                  const Text('Available Upgrades', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  ...addons.map((a) => _buildAddonCard(a)),
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
