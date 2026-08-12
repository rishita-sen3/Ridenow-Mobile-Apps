import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';

final kycProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return await ApiClient.get('/user/kyc');
});

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _aadhaarController = TextEditingController();
  final _dlController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitKyc() async {
    if (_aadhaarController.text.isEmpty || _dlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await ApiClient.post('/user/kyc/upload', {
        'aadhaar_number': _aadhaarController.text,
        'dl_number': _dlController.text,
      });

      if (response['message'] != null) {
        ref.refresh(kycProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit KYC')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycAsync = ref.watch(kycProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('KYC Verification', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: kycAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (kyc) {
          final status = kyc['status'] ?? 'not_submitted';

          if (status == 'not_submitted' || status == 'rejected') {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: status == 'rejected' ? Colors.red.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(status == 'rejected' ? Icons.warning : Icons.info, color: status == 'rejected' ? Colors.red : Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            status == 'rejected' 
                                ? 'Your previous KYC was rejected. Please resubmit valid documents.' 
                                : 'Please submit your KYC details to book rides.',
                            style: GoogleFonts.inter(
                              color: status == 'rejected' ? Colors.red.shade900 : Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Submit KYC', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _aadhaarController,
                    decoration: const InputDecoration(
                      labelText: 'Aadhaar Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dlController,
                    decoration: const InputDecoration(
                      labelText: 'Driving License Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.drive_eta),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitKyc,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF212529),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Submit Documents', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }

          // Approved or Pending State
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == 'approved' ? Icons.check_circle : Icons.hourglass_empty,
                    size: 80,
                    color: status == 'approved' ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    status == 'approved' ? 'KYC Approved' : 'KYC Pending Verification',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status == 'approved' 
                        ? 'You are verified and ready to book rides!' 
                        : 'Your documents are currently being reviewed by our team. Please check back later.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Submitted Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Aadhaar: ${kyc['aadhaar_number'] ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        Text('Driving License: ${kyc['dl_number'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
