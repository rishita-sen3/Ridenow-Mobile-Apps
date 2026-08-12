import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../core/providers.dart';
import 'vehicle_details_screen.dart';
import '../widgets/location_selector_bottom_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String initialFilter;
  const SearchScreen({super.key, this.initialFilter = 'All'});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late String _selectedFilter;
  String _selectedSort = 'nearest';
  int _selectedRadius = 10;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVehicles();
    });
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final loc = ref.read(locationProvider);
    
    try {
      final queryParams = {
        if (loc.lat != null) 'lat': loc.lat.toString(),
        if (loc.lng != null) 'lng': loc.lng.toString(),
        if (loc.city.isNotEmpty) 'city': loc.city,
        'radius': _selectedRadius.toString(),
        'sort': _selectedSort,
        if (_selectedFilter.toLowerCase() != 'all') 'category': _selectedFilter.toLowerCase(),
        if (_searchController.text.isNotEmpty) 'search': _searchController.text,
      };
      
      final queryString = Uri(queryParameters: queryParams).query;
      final response = await ApiClient.get('/vehicles?$queryString');
      
      if (response != null && response['data'] != null) {
        setState(() {
          _vehicles = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid response format';
        });
      }
    } catch (e) {
      debugPrint('Fetch error in SearchScreen: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _showSortFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Sort & Filter', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Text('Distance Radius', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [2, 5, 10, 20, 50].map((r) => ChoiceChip(
                          label: Text('Within $r km'),
                          selected: _selectedRadius == r,
                          onSelected: (val) {
                            if(val) setModalState(() => _selectedRadius = r);
                          },
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text('Sort By', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          {'id': 'nearest', 'name': 'Nearest'},
                          {'id': 'lowest_price', 'name': 'Lowest Price'},
                          {'id': 'highest_rating', 'name': 'Highest Rating'},
                          {'id': 'newest', 'name': 'Newest'},
                        ].map((s) => ChoiceChip(
                          label: Text(s['name']!),
                          selected: _selectedSort == s['id'],
                          onSelected: (val) {
                            if(val) setModalState(() => _selectedSort = s['id']!);
                          },
                        )).toList(),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () {
                            Navigator.pop(context);
                            _fetchVehicles();
                          },
                          child: Text('Apply', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationProvider);
    String locText = loc.city.isNotEmpty ? loc.city : (loc.lat != null ? 'Current Location' : 'Select City');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _fetchVehicles(),
            decoration: InputDecoration(
              hintText: 'Search vehicles...',
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.grey),
                onPressed: _fetchVehicles,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => const LocationSelectorBottomSheet());
                      _fetchVehicles();
                    },
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red.shade600, size: 18),
                        const SizedBox(width: 4),
                        Text(locText, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: _showSortFilterModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.tune, size: 16, color: Colors.black87),
                        const SizedBox(width: 4),
                        Text('Filter', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Bike', 'Scooter', 'Car', 'EVs', 'SUVs', 'Luxury'].map((filter) {
                  final isSelected = _selectedFilter.toLowerCase() == filter.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter, style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                        _fetchVehicles();
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: Colors.blue.shade700,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.transparent)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_errorMessage, style: GoogleFonts.inter(color: Colors.red), textAlign: TextAlign.center)))
                    : _vehicles.isEmpty
                        ? Center(child: Text('No vehicles found.', style: GoogleFonts.inter(color: Colors.grey)))
                        : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        final distance = vehicle['distance'] != null ? double.parse(vehicle['distance'].toString()).toStringAsFixed(1) : null;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                vehicle['image_url'] ?? 'https://via.placeholder.com/150',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(width: 80, color: Colors.grey.shade200, child: const Icon(Icons.image)),
              ),
            ),
            title: Text('${vehicle['brand']} ${vehicle['model']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${vehicle['shop']?['name'] ?? ''}, ${vehicle['shop']?['city'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                if (distance != null && distance != '0.0')
                  Text('$distance km away', style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('₹${vehicle['daily_rate'] ?? 0}/day', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
              ],
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailsScreen(
                vehicle: vehicle,
                shopId: vehicle['shop']?['id'] ?? 1,
                shopName: vehicle['shop']?['name'] ?? 'Shop',
              )));
            },
          ),
        );
      },
    );
  }
}
