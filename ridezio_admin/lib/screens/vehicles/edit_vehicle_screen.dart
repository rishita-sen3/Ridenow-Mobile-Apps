import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';
import '../../services/api_service.dart';
import '../../models/vehicle.dart';
import 'vehicles_screen.dart';

class EditVehicleScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;
  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  ConsumerState<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends ConsumerState<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _type;
  late String _status;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _regNoController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _dailyRateController;
  late TextEditingController _weeklyRateController;
  late TextEditingController _monthlyRateController;
  late TextEditingController _securityDepositController;
  
  late TextEditingController _colorController;
  late TextEditingController _fuelTypeController;
  late TextEditingController _seatingCapacityController;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _type = widget.vehicle.type.toLowerCase();
    _status = widget.vehicle.status.toLowerCase();
    _brandController = TextEditingController(text: widget.vehicle.brand);
    _modelController = TextEditingController(text: widget.vehicle.model);
    _regNoController = TextEditingController(text: widget.vehicle.registrationNumber);
    _hourlyRateController = TextEditingController(text: widget.vehicle.hourlyRate.toString());
    _dailyRateController = TextEditingController(text: widget.vehicle.dailyRate.toString());
    _weeklyRateController = TextEditingController(text: widget.vehicle.weeklyRate.toString());
    _monthlyRateController = TextEditingController(text: widget.vehicle.monthlyRate.toString());
    _securityDepositController = TextEditingController(text: widget.vehicle.securityDeposit.toString());
    _colorController = TextEditingController(text: widget.vehicle.color ?? '');
    _fuelTypeController = TextEditingController(text: widget.vehicle.fuelType ?? '');
    _seatingCapacityController = TextEditingController(text: widget.vehicle.seatingCapacity?.toString() ?? '');
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _regNoController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _weeklyRateController.dispose();
    _monthlyRateController.dispose();
    _securityDepositController.dispose();
    _colorController.dispose();
    _fuelTypeController.dispose();
    _seatingCapacityController.dispose();
    super.dispose();
  }

  Future<void> _updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final vehicleData = {
        'type': _type,
        'brand': _brandController.text,
        'model': _modelController.text,
        'registration_number': _regNoController.text,
        'hourly_rate': double.tryParse(_hourlyRateController.text) ?? 0,
        'daily_rate': double.tryParse(_dailyRateController.text) ?? 0,
        'weekly_rate': double.tryParse(_weeklyRateController.text) ?? 0,
        'monthly_rate': double.tryParse(_monthlyRateController.text) ?? 0,
        'security_deposit': double.tryParse(_securityDepositController.text) ?? 0,
        'status': _status,
        if (_colorController.text.isNotEmpty) 'color': _colorController.text,
        if (_fuelTypeController.text.isNotEmpty) 'fuel_type': _fuelTypeController.text,
        if (_seatingCapacityController.text.isNotEmpty) 'seating_capacity': int.tryParse(_seatingCapacityController.text) ?? 0,
      };

      final success = await ref.read(apiServiceProvider).updateVehicle(widget.vehicle.id!, vehicleData, imagePath: _imageFile?.path);
      if (success) {
        ref.refresh(vehiclesProvider({}));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle updated successfully')));
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const VehiclesScreen()), (route) => false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const VehiclesScreen()), (route) => false);
            }
          },
        ),
        title: Text(
          'Edit Vehicle',
          style: GoogleFonts.inter(
            color: const Color(0xFF212529),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                          )
                        : (widget.vehicle.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(widget.vehicle.imageUrl!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text('Tap to update vehicle image', style: GoogleFonts.inter(color: Colors.grey.shade600)),
                                ],
                              )),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildDropdown('Vehicle Type', _type, ['bike', 'scooter', 'car'], (v) => setState(() => _type = v!)),
              const SizedBox(height: 16),
              _buildTextField('Brand', _brandController, isRequired: true),
              const SizedBox(height: 16),
              _buildTextField('Model', _modelController, isRequired: true),
              const SizedBox(height: 16),
              _buildTextField('Registration Number', _regNoController, isRequired: true),
              const SizedBox(height: 24),
              Text('Rates & Deposit', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Hourly Rate (₹)', _hourlyRateController, isNumber: true, isRequired: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Daily Rate (₹)', _dailyRateController, isNumber: true, isRequired: true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Weekly Rate (₹)', _weeklyRateController, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Monthly Rate (₹)', _monthlyRateController, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Security Deposit (₹)', _securityDepositController, isNumber: true),
              const SizedBox(height: 24),
              Text('Specifications', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTextField('Color (optional)', _colorController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Fuel Type', _fuelTypeController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Seating Capacity', _seatingCapacityController, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdown('Status', _status, ['available', 'booked', 'maintenance', 'inactive'], (v) => setState(() => _status = v!)),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF212529),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Update Vehicle', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: isRequired ? (value) => value == null || value.isEmpty ? 'This field is required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
