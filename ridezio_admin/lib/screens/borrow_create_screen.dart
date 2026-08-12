import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class BorrowCreateScreen extends ConsumerStatefulWidget {
  const BorrowCreateScreen({super.key});

  @override
  ConsumerState<BorrowCreateScreen> createState() => _BorrowCreateScreenState();
}

class _BorrowCreateScreenState extends ConsumerState<BorrowCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _borrowerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemDescController = TextEditingController();
  final _amountController = TextEditingController(text: '0');

  DateTime _borrowDate = DateTime.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _borrowerNameController.dispose();
    _phoneController.dispose();
    _itemNameController.dispose();
    _itemDescController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final borrowData = {
        'borrower_name': _borrowerNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'item_name': _itemNameController.text.trim(),
        'item_description': _itemDescController.text.trim(),
        'amount': _amountController.text.trim(),
        'borrow_date': DateFormat('yyyy-MM-dd').format(_borrowDate),
        'expected_return_date': DateFormat('yyyy-MM-dd').format(_returnDate),
      };

      await ref.read(apiServiceProvider).createBorrow(borrowData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Borrow recorded successfully')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isBorrowDate) async {
    final initialDate = isBorrowDate ? _borrowDate : _returnDate;
    final firstDate = isBorrowDate ? DateTime(2000) : _borrowDate;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (isBorrowDate) {
          _borrowDate = picked;
          if (_returnDate.isBefore(_borrowDate)) {
            _returnDate = _borrowDate.add(const Duration(days: 1));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Borrow', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Borrower Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _borrowerNameController,
                decoration: const InputDecoration(labelText: 'Borrower Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              
              const SizedBox(height: 24),
              const Text('Item Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _itemDescController,
                decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount / Security Deposit (₹)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              const Text('Dates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Borrow Date', border: OutlineInputBorder()),
                        child: Text(DateFormat('MMM d, yyyy').format(_borrowDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Return Date', border: OutlineInputBorder()),
                        child: Text(DateFormat('MMM d, yyyy').format(_returnDate)),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Save Record', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
