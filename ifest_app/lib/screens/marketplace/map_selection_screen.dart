import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ifest_app/theme/app_theme.dart';

class MapSelectionResult {
  final GeoPoint geoPoint;
  final String region;
  final String address;

  MapSelectionResult({
    required this.geoPoint,
    required this.region,
    required this.address,
  });
}

class MapSelectionScreen extends StatefulWidget {
  final GeoPoint? initialLocation;

  const MapSelectionScreen({super.key, this.initialLocation});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(-23.550520, -46.633308); // Default: SP
  Marker? _selectedMarker;
  bool _isLoading = false;

  String _currentRegion = '';
  String _currentAddress = '';

  Timer? _debounce;
  List<dynamic> _predictions = [];
  final String _googleApiKey = 'AIzaSyDpOPqHf9wkwYA5yiT17TIGimOKE7Ll248';

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _setMarker(_currentLocation);
      _reverseGeocode(_currentLocation);
    } else {
      _getUserCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (widget.initialLocation == null && _currentLocation.latitude != -23.550520) {
      _mapController?.moveCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 16),
      );
    }
  }

  Future<void> _getUserCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      await _setMarker(latLng);
      await _reverseGeocode(latLng);
      
      if (mounted) {
        setState(() {
          _currentLocation = latLng;
        });
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 16),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error getting current location in map: $e");
    }
  }

  Future<void> _setMarker(LatLng position) async {
    setState(() {
      _currentLocation = position;
      _selectedMarker = Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueMagenta,
        ),
      );
    });
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          final city =
              place.subAdministrativeArea ??
              place.locality ??
              place.administrativeArea ??
              '';
          final state = place.administrativeArea ?? '';

          _currentRegion = '$city - $state'.trim();
          if (_currentRegion.startsWith('-')) {
            _currentRegion = _currentRegion.substring(1).trim();
          }

          final street = place.street ?? place.thoroughfare ?? '';
          final num = place.subThoroughfare ?? '';
          final neighborhood = place.subLocality ?? '';

          _currentAddress = '$street, $num - $neighborhood'.trim();
          if (_currentAddress.startsWith(',')) {
            _currentAddress = _currentAddress.substring(1).trim();
          }

          // Update search field to show the address
          _searchController.text = _currentAddress.isNotEmpty
              ? _currentAddress
              : _currentRegion;
        });
      }
    } catch (e) {
      debugPrint("Error on reverse geocoding: $e");
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _predictions = []; // Hide predictions on search
    });

    try {
      List<Location> locations = await Geocoding().locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final position = LatLng(loc.latitude, loc.longitude);

        await _setMarker(position);
        await _reverseGeocode(position);

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: position, zoom: 16),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Endereço não encontrado')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao buscar endereço: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapTap(LatLng position) async {
    setState(
      () => _predictions = [],
    ); // Hide predictions when interacting with map
    await _setMarker(position);
    await _reverseGeocode(position);
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.isNotEmpty) {
        _fetchSuggestions(value);
      } else {
        setState(() => _predictions = []);
      }
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&components=country:br&language=pt-BR';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _predictions = data['predictions'];
          });
        } else {
          setState(() => _predictions = []);
        }
      }
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
    }
  }

  void _confirmSelection() {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um local no mapa')),
      );
      return;
    }

    final result = MapSelectionResult(
      geoPoint: GeoPoint(_currentLocation.latitude, _currentLocation.longitude),
      region: _currentRegion,
      address: _currentAddress,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Localização'),
        backgroundColor: context.backgroundColor,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 14,
            ),
            markers: _selectedMarker != null ? {_selectedMarker!} : {},
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: 'Pesquisar endereço...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onSubmitted: (_) => _searchAddress(),
                        ),
                      ),
                      _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.search,
                                color: context.primaryColor,
                              ),
                              onPressed: _searchAddress,
                            ),
                    ],
                  ),
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _predictions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final prediction = _predictions[index];
                        return ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: context.primaryColor,
                          ),
                          title: Text(
                            prediction['description'],
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            _searchController.text = prediction['description'];
                            FocusScope.of(context).unfocus(); // Close keyboard
                            _searchAddress();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Confirm Button
          if (_selectedMarker != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Confirmar Localização',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
