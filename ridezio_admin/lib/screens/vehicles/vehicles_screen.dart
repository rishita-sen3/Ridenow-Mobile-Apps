import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../services/api_service.dart';
import '../../models/vehicle.dart';
import '../../widgets/main_drawer.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  final Map<String, String> filters;
  const VehiclesScreen({super.key, this.filters = const {}});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider(widget.filters));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F6F6),
      drawer: const MainDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Manage Vehicles',
          style: GoogleFonts.inter(
            color: const Color(0xFF212529),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(vehiclesProvider(widget.filters).future),
        child: vehiclesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Error: $err'),
              )
            ],
          ),
          data: (vehicles) {
            final filteredVehicles = _searchQuery.isEmpty
                ? vehicles
                : vehicles.where((v) {
                    final q = _searchQuery.toLowerCase();
                    return v.brand.toLowerCase().contains(q) ||
                        v.model.toLowerCase().contains(q) ||
                        v.registrationNumber.toLowerCase().contains(q) ||
                        v.type.toLowerCase().contains(q);
                  }).toList();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildVehiclesTable(filteredVehicles),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'All Vehicles',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF212529),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Vehicle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF212529),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildVehiclesTable(List<Vehicle> vehicles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search vehicles...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          const Divider(height: 1),
          if (vehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No vehicles found.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingTextStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6c757d),
                ),
                dataTextStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF212529),
                ),
                columns: const [
                  DataColumn(label: Text('VEHICLE')),
                  DataColumn(label: Text('REG NUMBER')),
                  DataColumn(label: Text('TYPE')),
                  DataColumn(label: Text('DAILY RATE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: vehicles.map((vehicle) {
                  return DataRow(
                    onSelectChanged: (_) => _showVehicleDetails(context, vehicle),
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            if (vehicle.imageUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  vehicle.imageUrl!,
                                  width: 40,
                                  height: 30,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(Icons.directions_car, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text('${vehicle.brand} ${vehicle.model}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        )
                      ),
                      DataCell(Text(vehicle.registrationNumber)),
                      DataCell(Text(vehicle.type.toUpperCase())),
                      DataCell(Text('₹${vehicle.dailyRate.toStringAsFixed(2)}')),
                      DataCell(_buildStatusBadge(vehicle.status)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EditVehicleScreen(vehicle: vehicle)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Vehicle'),
                                    content: Text('Are you sure you want to delete ${vehicle.brand} ${vehicle.model}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          try {
                                            await ref.read(apiServiceProvider).deleteVehicle(vehicle.id!);
                                            ref.refresh(vehiclesProvider(widget.filters).future);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Vehicle deleted successfully')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'available':
        color = Colors.green;
        break;
      case 'booked':
        color = Colors.blue;
        break;
      case 'maintenance':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showVehicleDetails(BuildContext context, Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (vehicle.imageUrl != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          vehicle.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.directions_car, size: 64, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle.brand} ${vehicle.model}',
                          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildStatusBadge(vehicle.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reg No: ${vehicle.registrationNumber}',
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Pricing Details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Hourly Rate', '₹${vehicle.hourlyRate.toStringAsFixed(2)}'),
                  _buildDetailRow('Daily Rate', '₹${vehicle.dailyRate.toStringAsFixed(2)}'),
                  _buildDetailRow('Weekly Rate', '₹${vehicle.weeklyRate.toStringAsFixed(2)}'),
                  _buildDetailRow('Monthly Rate', '₹${vehicle.monthlyRate.toStringAsFixed(2)}'),
                  _buildDetailRow('Security Deposit', '₹${vehicle.securityDeposit.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Vehicle Specifications', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Type', vehicle.type.toUpperCase()),
                  _buildDetailRow('Color', vehicle.color ?? 'N/A'),
                  _buildDetailRow('Fuel Type', vehicle.fuelType ?? 'N/A'),
                  _buildDetailRow('Seating Capacity', vehicle.seatingCapacity?.toString() ?? 'N/A'),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade600)),
          Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}
