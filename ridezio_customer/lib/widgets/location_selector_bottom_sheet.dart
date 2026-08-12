import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../core/providers.dart';
import '../core/api_client.dart';

class LocationSelectorBottomSheet extends ConsumerStatefulWidget {
  const LocationSelectorBottomSheet({super.key});

  @override
  ConsumerState<LocationSelectorBottomSheet> createState() => _LocationSelectorBottomSheetState();
}

class _LocationSelectorBottomSheetState extends ConsumerState<LocationSelectorBottomSheet> {
  List<dynamic> _cityData = [];
  bool _isLoading = true;
  bool _isLocating = false;
  int? _selectedStateIndex;
  int? _selectedCityIndex;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final response = await http.get(Uri.parse('${ApiClient.baseUrl.replaceAll('/api', '')}/indian_cities.json'));
      if (response.statusCode == 200) {
        setState(() {
          _cityData = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Location', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Text('State', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<int>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Select State'),
                    value: _selectedStateIndex,
                    items: List.generate(_cityData.length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(_cityData[index]['state']),
                      );
                    }),
                    onChanged: (val) {
                      setState(() {
                        _selectedStateIndex = val;
                        _selectedCityIndex = null;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('City', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<int>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Select City'),
                    value: _selectedCityIndex,
                    items: _selectedStateIndex == null ? [] : List.generate(_cityData[_selectedStateIndex!]['cities'].length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(_cityData[_selectedStateIndex!]['cities'][index]['name']),
                      );
                    }),
                    onChanged: _selectedStateIndex == null ? null : (val) {
                      setState(() {
                        _selectedCityIndex = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _selectedCityIndex == null ? null : () async {
                      final stateName = _cityData[_selectedStateIndex!]['state'];
                      final city = _cityData[_selectedStateIndex!]['cities'][_selectedCityIndex!];
                      
                      double lat = double.tryParse(city['lat']?.toString() ?? '0') ?? 0.0;
                      double lng = double.tryParse(city['lng']?.toString() ?? '0') ?? 0.0;
                      
                      await ref.read(locationProvider.notifier).setLocation(
                        stateName, 
                        city['name'], 
                        lat, 
                        lng
                      );
                      
                      ref.invalidate(exploreProvider);
                      
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text('Save Location', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
