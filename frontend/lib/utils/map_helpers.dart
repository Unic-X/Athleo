import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class PaceHelpers {
  double speed(LatLng p1, LatLng p2, int timeTaken) {
    var lat1 = p1.latitude;
    var lon1 = p1.longitude;
    var lat2 = p2.latitude;
    var lon2 = p2.longitude;
    var R = 6378.137; // Radius of earth in KM
    var dLat = lat2 * pi / 180 - lat1 * pi / 180;
    var dLon = lon2 * pi / 180 - lon1 * pi / 180;
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    var d = R * c;
    return d * 1000 / timeTaken;
  }
}
