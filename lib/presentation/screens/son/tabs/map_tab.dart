import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/localization.dart';
import '../../../../core/theme.dart';
import '../../../../logic/language/language_cubit.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  double _lat = 24.7136; // Riyadh coordinates baseline
  double _lng = 46.6753;
  bool _isLocating = false;
  StreamSubscription<fs.DocumentSnapshot>? _locationSubscription;
  Timer? _mockTimer;
  final List<String> _movementLogs = [];

  bool get _isFirebaseEnabled {
    try {
      return fs.FirebaseFirestore.instance.app.name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _startLocationStreaming();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mockTimer?.cancel();
    super.dispose();
  }

  void _startLocationStreaming() {
    setState(() {
      _isLocating = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (_isFirebaseEnabled && user != null) {
      final docRef = fs.FirebaseFirestore.instance.collection('users').doc(user.uid);
      _locationSubscription = docRef.snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          final geoPoint = data['lastLocation'] as fs.GeoPoint?;

          if (geoPoint != null) {
            if (mounted) {
              setState(() {
                _lat = geoPoint.latitude;
                _lng = geoPoint.longitude;
                _isLocating = false;

                final now = DateTime.now();
                final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

                _movementLogs.insert(0, '[Firestore GPS $formattedTime] Lat: ${_lat.toStringAsFixed(6)}, Lng: ${_lng.toStringAsFixed(6)}');
                if (_movementLogs.length > 5) {
                  _movementLogs.removeLast();
                }
              });
            }
          }
        }
      }, onError: (err) {
        debugPrint("Error listening to father location: $err");
        if (mounted) {
          setState(() {
            _isLocating = false;
          });
        }
      });
    } else {
      _mockTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          final rand = Random();
          final deltaLat = (rand.nextDouble() - 0.5) * 0.0005;
          final deltaLng = (rand.nextDouble() - 0.5) * 0.0005;

          setState(() {
            _lat += deltaLat;
            _lng += deltaLng;
            _isLocating = false;

            final now = DateTime.now();
            final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

            _movementLogs.insert(0, '[Mock GPS $formattedTime] Lat: ${_lat.toStringAsFixed(6)}, Lng: ${_lng.toStringAsFixed(6)}');
            if (_movementLogs.length > 5) {
              _movementLogs.removeLast();
            }
          });
        }
      });
    }
  }

  void _refreshLocation() {
    setState(() {
      _isLocating = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (_isFirebaseEnabled && user != null) {
      fs.FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          final geoPoint = data['lastLocation'] as fs.GeoPoint?;
          if (geoPoint != null) {
            if (mounted) {
              setState(() {
                _lat = geoPoint.latitude;
                _lng = geoPoint.longitude;
                _isLocating = false;
              });
            }
          }
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _isLocating = false;
          });
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLocating = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<LanguageCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalization.translate('live_tracking', langCode),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: GridPaper(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                        interval: 50.0,
                        divisions: 2,
                        subdivisions: 1,
                      ),
                    ),

                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.05),
                        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                      ),
                    ),
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.08),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                    ),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.elderly_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.darkNavy,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            langCode == 'ar' ? 'موقع الأب الحالي' : 'Father\'s Position',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),

                    if (_isLocating)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.darkNavy.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalization.translate('father_coordinates', langCode),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.inputBgDark : AppColors.inputBgLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppLocalization.translate('lat', langCode),
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                            Text(
                              _lat.toStringAsFixed(6),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.inputBgDark : AppColors.inputBgLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppLocalization.translate('lng', langCode),
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                            Text(
                              _lng.toStringAsFixed(6),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _refreshLocation,
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(AppLocalization.translate('track_now', langCode)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView(
                children: _movementLogs.isEmpty
                    ? [
                  Text(
                    langCode == 'ar' ? 'بانتظار إشارات GPS البث...' : 'Waiting for GPS streaming signals...',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                    textAlign: TextAlign.center,
                  )
                ]
                    : _movementLogs.map((log) => Text(
                  log,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.blueGrey),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
