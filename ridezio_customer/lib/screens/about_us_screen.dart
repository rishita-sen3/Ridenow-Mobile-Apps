import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About Us', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF212529),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo.png', height: 48),
                      const SizedBox(width: 12),
                      Text('Ridezio', style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Your Journey, Your Way', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade400)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Our Mission', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              'At Ridezio, we believe that mobility should be accessible, seamless, and transparent. Our mission is to connect people with the perfect vehicles for their journeys, whether it is a quick city errand or a week-long road trip.',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text('Why Choose Us?', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFeature('Verified Vehicles', 'Every vehicle on our platform undergoes strict quality checks.'),
            _buildFeature('Transparent Pricing', 'No hidden fees. What you see is what you pay.'),
            _buildFeature('24/7 Support', 'Our dedicated team is always here to help you when you need it.'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
