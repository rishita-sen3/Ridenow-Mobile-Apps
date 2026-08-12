import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('How It Works', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rent a vehicle in 3 easy steps:', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _buildStep(
              step: '1',
              title: 'Find Your Perfect Ride',
              description: 'Browse our extensive collection of vehicles from trusted shops. Filter by location, price, and vehicle type to find exactly what you need.',
              icon: Icons.search,
            ),
            const SizedBox(height: 24),
            _buildStep(
              step: '2',
              title: 'Book and Pay',
              description: 'Select your dates, confirm your booking, and pay securely through our platform. We hold a small security deposit until you return the vehicle.',
              icon: Icons.payment,
            ),
            const SizedBox(height: 24),
            _buildStep(
              step: '3',
              title: 'Pick Up and Drive',
              description: 'Head to the shop location, show your booking reference, and get the keys. Enjoy your ride and return it when you are done!',
              icon: Icons.directions_car,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required String step, required String title, required String description, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(step, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(description, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
