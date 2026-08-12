import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/campaign.dart';

final campaignsProvider = FutureProvider.autoDispose<List<Campaign>>((ref) async {
  return ref.read(apiServiceProvider).getCampaigns();
});

class MarketingScreen extends ConsumerStatefulWidget {
  const MarketingScreen({super.key});

  @override
  ConsumerState<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends ConsumerState<MarketingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _code = '';
  String _discountType = 'percentage';
  String _discountValue = '';
  String _startDate = '';
  String _endDate = '';
  String _minDays = '';
  String _details = '';
  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _endDate = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _submitCampaign() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate.isEmpty || _endDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end dates.')));
      return;
    }
    
    _formKey.currentState!.save();
    
    setState(() => _isSubmitting = true);
    
    try {
      await ref.read(apiServiceProvider).createCampaign({
        'title': _title,
        'code': _code,
        'discount_type': _discountType,
        'discount_value': _discountValue,
        'start_date': _startDate,
        'end_date': _endDate,
        if (_minDays.isNotEmpty) 'min_days': _minDays,
        if (_details.isNotEmpty) 'details': _details,
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campaign created successfully!')));
        ref.refresh(campaignsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteCampaign(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Campaign?'),
        content: const Text('Are you sure you want to delete this campaign? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(apiServiceProvider).deleteCampaign(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campaign deleted.')));
        ref.refresh(campaignsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showNewCampaignDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Campaign'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Campaign Title', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _title = val ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Promo Code (e.g. MONSOON20)', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _code = val ?? '',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _discountType,
                  decoration: const InputDecoration(labelText: 'Discount Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (₹)')),
                  ],
                  onChanged: (val) => setState(() => _discountType = val ?? 'percentage'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _discountValue = val ?? '',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate.isEmpty ? 'Start Date' : _startDate),
                        onPressed: () => _selectDate(context, true),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate.isEmpty ? 'End Date' : _endDate),
                        onPressed: () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Min Booking Days (Optional)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => _minDays = val ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Details (Optional)', border: OutlineInputBorder()),
                  onSaved: (val) => _details = val ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitCampaign,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator()) : const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(campaignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketing Tools'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewCampaignDialog,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
      ),
      body: campaignsAsync.when(
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return const Center(child: Text('No marketing campaigns running right now.', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                                Text(campaign.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(4)),
                                  child: Text(campaign.code, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: campaign.status == 'active' ? Colors.green : Colors.grey, borderRadius: BorderRadius.circular(16)),
                            child: Text(campaign.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${campaign.discountType == 'percentage' ? '${campaign.discountValue}%' : '₹${campaign.discountValue}'} OFF',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (campaign.details != null && campaign.details!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(campaign.details!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.event, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(child: Text('${campaign.startDate} to ${campaign.endDate}', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                            onPressed: () => _deleteCampaign(campaign.id),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(left: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
