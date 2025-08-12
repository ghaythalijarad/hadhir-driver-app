// This file has been deprecated. Use mapbox_widget.dart instead.
import 'package:flutter/material.dart';

import '../utils/coordinates.dart';
import 'mapbox_widget.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MapboxWidget(
      isOnline: true,
      initialLocation: const LatLng(33.3152, 44.3661).toMapboxPoint(),
    );
  }
}
