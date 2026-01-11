import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapSelectPage extends StatefulWidget {
  const MapSelectPage({super.key});

  @override
  State<MapSelectPage> createState() => _MapSelectPageState();
}

class _MapSelectPageState extends State<MapSelectPage> {
  GoogleMapController? mapController;
  LatLng? selectedPosition; // Kullanıcının seçtiği nokta
  LatLng? currentPosition; // Cihazın mevcut konumu

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  //  Cihazın mevcut konumunu al
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentPosition = LatLng(pos.latitude, pos.longitude);
      selectedPosition = currentPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tarlanın Konumunu Seç")),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: currentPosition!,
                zoom: 15,
              ),
              // Kullanıcı haritada bir noktaya tıkladığında
              onTap: (pos) {
                setState(() {
                  selectedPosition = pos;
                });
              },
              markers: selectedPosition != null
                  ? {
                      Marker(
                        markerId: const MarkerId("selected"),
                        position: selectedPosition!,
                        infoWindow: const InfoWindow(title: "Tarla Konumu"),
                      ),
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        onPressed: () {
          if (selectedPosition != null) {
            // Seçilen konumu geri gönder
            Navigator.pop(context, selectedPosition);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Lütfen bir konum seçin.")),
            );
          }
        },
        label: const Text("Seçimi Onayla"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
