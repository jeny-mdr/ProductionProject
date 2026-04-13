import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() =>
      _HospitalsScreenState();
}

class _HospitalsScreenState
    extends State<HospitalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _hospitals   = [];
  List<dynamic> _pharmacies  = [];
  bool          _loading     = true;
  String?       _error;
  double?       _userLat;
  double?       _userLng;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
        length: 2, vsync: this);
    _getLocationAndFetch();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocationAndFetch() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      LocationPermission perm =
      await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator
            .requestPermission();
      }

      Position? pos;
      if (perm !=
          LocationPermission.deniedForever &&
          perm != LocationPermission.denied) {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      }

      // Default to Kathmandu if no GPS
      final lat = pos?.latitude  ?? 27.7172;
      final lng = pos?.longitude ?? 85.3240;

      setState(() {
        _userLat = lat;
        _userLng = lng;
      });

      await _fetchData(lat, lng);
    } catch (e) {
      // Use Kathmandu as fallback
      await _fetchData(27.7172, 85.3240);
    }
  }

  Future<void> _fetchData(
      double lat, double lng) async {
    final token =
        context.read<AuthProvider>().token;
    try {
      final hRes = await http.get(
        Uri.parse(
            '$kHospitalsUrl?lat=$lat&lng=$lng'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );
      final pRes = await http.get(
        Uri.parse(
            '$kPharmaciesUrl?lat=$lat&lng=$lng'),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      if (hRes.statusCode == 200 &&
          pRes.statusCode == 200) {
        final hData = jsonDecode(hRes.body);
        final pData = jsonDecode(pRes.body);
        setState(() {
          _hospitals  =
              hData['hospitals'] ?? [];
          _pharmacies =
              pData['pharmacies'] ?? [];
          _loading    = false;
        });
      } else {
        setState(() {
          _error   = 'Failed to load data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error   = 'Cannot reach server';
        _loading = false;
      });
    }
  }

  Future<void> _openDirections(
      String mapLink) async {
    final uri = Uri.parse(mapLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,
          mode:
          LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealioColors.bg,
      appBar: AppBar(
        backgroundColor: HealioColors.primary,
        foregroundColor: Colors.white,
        title: Text('Nearby',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white),
          onPressed: () =>
              Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white),
            onPressed: _getLocationAndFetch,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor:
          Colors.white60,
          labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13),
          tabs: const [
            Tab(
                icon: Icon(
                    Icons
                        .local_hospital_rounded,
                    size: 18),
                text: 'Hospitals'),
            Tab(
                icon: Icon(
                    Icons.local_pharmacy_rounded,
                    size: 18),
                text: 'Pharmacies'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                color:
                HealioColors.primary),
            SizedBox(height: 16),
            Text('Finding nearby...',
                style: TextStyle(
                    color: HealioColors
                        .textMid)),
          ],
        ),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: HealioColors
                    .textLight),
            const SizedBox(height: 12),
            Text(_error!,
                style:
                GoogleFonts.poppins(
                    color: HealioColors
                        .textMid)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
              _getLocationAndFetch,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : TabBarView(
        controller: _tabCtrl,
        children: [
          _NearbyTab(
            items:      _hospitals,
            userLat:    _userLat ?? 27.7172,
            userLng:    _userLng ?? 85.3240,
            type:       'hospital',
            onDirections: _openDirections,
          ),
          _NearbyTab(
            items:      _pharmacies,
            userLat:    _userLat ?? 27.7172,
            userLng:    _userLng ?? 85.3240,
            type:       'pharmacy',
            onDirections: _openDirections,
          ),
        ],
      ),
    );
  }
}

class _NearbyTab extends StatelessWidget {
  final List<dynamic>          items;
  final double                 userLat;
  final double                 userLng;
  final String                 type;
  final Function(String)       onDirections;

  const _NearbyTab({
    required this.items,
    required this.userLat,
    required this.userLng,
    required this.type,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              type == 'hospital'
                  ? Icons.local_hospital_rounded
                  : Icons.local_pharmacy_rounded,
              size: 72,
              color: HealioColors.primaryMid,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type}s found nearby',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: HealioColors.textMid,
              ),
            ),
          ],
        ),
      );
    }

    // Build map markers
    final markers = items.map((item) {
      final lat = item['latitude'] ??
          item['lat'] ?? 0.0;
      final lng = item['longitude'] ??
          item['lng'] ?? 0.0;
      return Marker(
        point: LatLng(
            (lat as num).toDouble(),
            (lng as num).toDouble()),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () =>
              onDirections(item['map_link']),
          child: Container(
            decoration: BoxDecoration(
              color: type == 'hospital'
                  ? HealioColors.primary
                  : HealioColors.accent,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white,
                  width: 2),
            ),
            child: Icon(
              type == 'hospital'
                  ? Icons
                  .local_hospital_rounded
                  : Icons
                  .local_pharmacy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();

    // Add user marker
    markers.add(Marker(
      point: LatLng(userLat, userLng),
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white, width: 2),
        ),
        child: const Icon(
            Icons.person_pin_circle_rounded,
            color: Colors.white,
            size: 22),
      ),
    ));

    return Column(
      children: [
        // Map
        SizedBox(
          height: 280,
          child: FlutterMap(
            options: MapOptions(
              initialCenter:
              LatLng(userLat, userLng),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                'com.example.healio',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return _PlaceCard(
                item:         item,
                type:         type,
                onDirections: onDirections,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String               type;
  final Function(String)     onDirections;

  const _PlaceCard({
    required this.item,
    required this.type,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final name     = item['name'] ?? '';
    final address  = item['address'] ?? '';
    final distance =
        item['distance_km'] ?? 0.0;
    final mapLink  = item['map_link'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealioColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: HealioColors.border),
        boxShadow: [
          BoxShadow(
            color: HealioColors.primary
                .withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: type == 'hospital'
                ? HealioColors.primaryLight
                : HealioColors.accentLight,
            borderRadius:
            BorderRadius.circular(12),
          ),
          child: Icon(
            type == 'hospital'
                ? Icons.local_hospital_rounded
                : Icons.local_pharmacy_rounded,
            color: type == 'hospital'
                ? HealioColors.primary
                : HealioColors.accent,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HealioColors.textDark,
                  )),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(address,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: HealioColors.textMid,
                    ),
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis),
              ],
              const SizedBox(height: 4),
              Row(children: [
                const Icon(
                    Icons.location_on_rounded,
                    size: 12,
                    color: HealioColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${distance.toStringAsFixed(1)} km away',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: HealioColors.primary,
                  ),
                ),
              ]),
            ],
          ),
        ),

        // Directions button
        GestureDetector(
          onTap: () => onDirections(mapLink),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: HealioColors.primary,
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: Column(children: [
              const Icon(
                  Icons.directions_rounded,
                  color: Colors.white,
                  size: 18),
              Text('Go',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )),
            ]),
          ),
        ),
      ]),
    );
  }
}