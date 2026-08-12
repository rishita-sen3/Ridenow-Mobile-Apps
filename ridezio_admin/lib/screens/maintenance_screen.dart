import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/vehicle.dart';

final maintenanceVehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  return ref.read(apiServiceProvider).getVehicles();
});

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, int id, String status, String message) async {
    try {
      await ref.read(apiServiceProvider).updateVehicle(id, {'status': status});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      ref.refresh(maintenanceVehiclesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsyncValue = ref.watch(maintenanceVehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Maintenance'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: vehiclesAsyncValue.when(
        data: (vehicles) {
          final maintenanceVehicles = vehicles.where((v) => v.status == 'maintenance').toList();
          final activeVehicles = vehicles.where((v) => v.status == 'available' || v.status == 'booked').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Vehicles In Maintenance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 12),
              if (maintenanceVehicles.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('All vehicles are currently operational. No vehicles in maintenance.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                  ),
                )
              else
                ...maintenanceVehicles.map((vehicle) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.build, color: Colors.orange),
                    title: Text('${vehicle.brand} ${vehicle.model}'),
                    subtitle: Text(vehicle.registrationNumber ?? 'No Reg'),
                    trailing: ElevatedButton(
                      onPressed: () => _updateStatus(context, ref, vehicle.id!, 'available', 'Vehicle marked as fixed!'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Mark Fixed', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                )),

              const SizedBox(height: 24),
              const Text('Operational Fleet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 12),
              if (activeVehicles.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No operational vehicles.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                  ),
                )
              else
                ...activeVehicles.map((vehicle) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.car_rental, color: Colors.green),
                    title: Text('${vehicle.brand} ${vehicle.model}'),
                    subtitle: Text('${vehicle.registrationNumber ?? 'No Reg'} - ${vehicle.status.toUpperCase()}'),
                    trailing: ElevatedButton(
                      onPressed: () => _updateStatus(context, ref, vehicle.id!, 'maintenance', 'Vehicle sent to garage!'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('Send to Garage', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
