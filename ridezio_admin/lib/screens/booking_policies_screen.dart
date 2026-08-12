import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class BookingPoliciesScreen extends ConsumerStatefulWidget {
  const BookingPoliciesScreen({super.key});

  @override
  ConsumerState<BookingPoliciesScreen> createState() => _BookingPoliciesScreenState();
}

class _BookingPoliciesScreenState extends ConsumerState<BookingPoliciesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _policy = {};

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchPolicy();
  }

  Future<void> _fetchPolicy() async {
    try {
      final data = await ref.read(apiServiceProvider).getBookingPolicy();
      setState(() {
        _policy = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _savePolicy() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    try {
      final updatedData = await ref.read(apiServiceProvider).updateBookingPolicy(_policy);
      setState(() {
        _policy = updatedData;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Policy saved successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Booking Policies', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: const TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: 'Cancellation'),
              Tab(text: 'Extension'),
              Tab(text: 'Late Return'),
            ],
          ),
          actions: [
            if (_isSaving) const Center(child: Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
            if (!_isSaving && !_isLoading)
              TextButton(
                onPressed: _savePolicy,
                child: const Text('Save', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: TabBarView(
                  children: [
                    _buildCancellationTab(),
                    _buildExtensionTab(),
                    _buildLateReturnTab(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCancellationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSwitchTile('Enable Custom Policy', 'allow_custom_policy', 'If disabled, platform policy applies'),
          const SizedBox(height: 16),
          _buildNumberField('Free Cancellation Hours', 'free_cancel_hours', 'e.g., 24'),
          const SizedBox(height: 16),
          _buildSectionTitle('Cancellation Slabs'),
          _buildSlabRow(1),
          _buildSlabRow(2),
          _buildSlabRow(3),
          const SizedBox(height: 16),
          _buildNumberField('Refund Processing Days', 'refund_days', 'e.g., 5'),
        ],
      ),
    );
  }

  Widget _buildExtensionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Extension Pricing'),
          _buildNumberField('Extension Hourly Rate (₹)', 'extension_hourly_rate', 'e.g., 100'),
          const SizedBox(height: 16),
          _buildNumberField('Extension Daily Rate (₹)', 'extension_daily_rate', 'e.g., 1000'),
          const SizedBox(height: 16),
          _buildNumberField('Maximum Extension Hours', 'maximum_extension_hours', 'e.g., 48'),
        ],
      ),
    );
  }

  Widget _buildLateReturnTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Late Returns & Damages'),
          _buildNumberField('Late Return Hourly Charge (₹)', 'late_return_hourly_charge', 'e.g., 150'),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _policy['damage_policy']?.toString() ?? '',
            decoration: InputDecoration(
              labelText: 'Damage Policy Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 4,
            onSaved: (val) => _policy['damage_policy'] = val,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String key, String subtitle) {
    bool value = (_policy[key] == 1 || _policy[key] == true || _policy[key] == '1');
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        value: value,
        activeThumbColor: Colors.blueAccent,
        onChanged: (val) {
          setState(() {
            _policy[key] = val ? 1 : 0;
          });
        },
      ),
    );
  }

  Widget _buildNumberField(String label, String key, String hint) {
    return TextFormField(
      initialValue: _policy[key]?.toString() ?? '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      onSaved: (val) => _policy[key] = val,
    );
  }

  Widget _buildSlabRow(int slabIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Slab $slabIndex', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildNumberField('From (hrs)', 'slab_${slabIndex}_from', 'e.g., 24')),
              const SizedBox(width: 8),
              Expanded(child: _buildNumberField('To (hrs)', 'slab_${slabIndex}_to', 'e.g., 48')),
              const SizedBox(width: 8),
              Expanded(child: _buildNumberField('Charge (%)', 'slab_${slabIndex}_percentage', '0-100')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}
