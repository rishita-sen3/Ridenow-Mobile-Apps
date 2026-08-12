import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'booking_policies_screen.dart';
import 'package:geolocator/geolocator.dart';

final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getSettings();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  late TextEditingController _shopNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _gstController;
  late TextEditingController _upiController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();

    _shopNameController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();
    _gstController = TextEditingController();
    _upiController = TextEditingController();
    _latController = TextEditingController();
    _lngController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstController.dispose();
    _upiController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _populateForm(Map<String, dynamic> data) {
    if (_firstNameController.text.isEmpty && data['user'] != null) {
      _firstNameController.text = data['user']['first_name'] ?? '';
      _lastNameController.text = data['user']['last_name'] ?? '';
      _emailController.text = data['user']['email'] ?? '';
      _phoneController.text = data['user']['phone'] ?? '';
    }
    if (_shopNameController.text.isEmpty && data['shop'] != null) {
      _shopNameController.text = data['shop']['name'] ?? '';
      _addressController.text = data['shop']['address'] ?? '';
      _cityController.text = data['shop']['city'] ?? '';
      _stateController.text = data['shop']['state'] ?? '';
      _pincodeController.text = data['shop']['pincode'] ?? '';
      _gstController.text = data['shop']['gst_number'] ?? '';
      _upiController.text = data['shop']['upi_id'] ?? '';
      _latController.text = data['shop']['latitude']?.toString() ?? '';
      _lngController.text = data['shop']['longitude']?.toString() ?? '';
    }
  }

  Future<void> _detectLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
        return;
      } 
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detecting location...')));
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location detected successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error detecting location: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
        'shop_name': _shopNameController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'gst_number': _gstController.text,
        'upi_id': _upiController.text,
        if (_latController.text.isNotEmpty) 'latitude': _latController.text,
        if (_lngController.text.isNotEmpty) 'longitude': _lngController.text,
      };

      await ref.read(apiServiceProvider).updateSettings(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        ref.refresh(settingsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildGlassCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.blue.withValues(alpha: 0.03),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) => label.contains('Optional') ? null : (value == null || value.isEmpty ? 'Required field' : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_isSaving) const Center(child: Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
          if (!_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save, color: Colors.blueAccent),
                label: const Text('Save', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: asyncSettings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          _populateForm(data);
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildGlassCard(
                    title: 'Profile Information',
                    children: [
                      _buildTextField(_firstNameController, 'First Name', Icons.person),
                      _buildTextField(_lastNameController, 'Last Name (Optional)', Icons.person_outline),
                      _buildTextField(_emailController, 'Email', Icons.email, isEmail: true),
                      _buildTextField(_phoneController, 'Phone Number', Icons.phone),
                      _buildTextField(_passwordController, 'New Password (Optional)', Icons.lock, isPassword: true),
                    ],
                  ),
                  _buildGlassCard(
                    title: 'Shop Details',
                    children: [
                      _buildTextField(_shopNameController, 'Shop Name', Icons.storefront),
                      _buildTextField(_addressController, 'Address', Icons.location_on),
                      _buildTextField(_cityController, 'City', Icons.location_city),
                      _buildTextField(_stateController, 'State', Icons.map),
                      _buildTextField(_pincodeController, 'Pincode', Icons.pin_drop),
                      _buildTextField(_gstController, 'GST Number (Optional)', Icons.receipt),
                      _buildTextField(_upiController, 'UPI ID (For receiving payments)', Icons.account_balance_wallet),
                      
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_latController, 'Latitude', Icons.explore)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_lngController, 'Longitude', Icons.explore)),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _detectLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Auto-Detect Shop Location'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    title: 'Advanced Settings',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.policy, color: Colors.blueAccent),
                        title: const Text('Booking Policies', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Manage cancellation, extension & late return rules'),
                        trailing: const Icon(Icons.chevron_right),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BookingPoliciesScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
