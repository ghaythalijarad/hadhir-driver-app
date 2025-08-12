class DriverProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String city;
  final String vehicleType;
  final String licenseNumber;
  final String nationalId;
  final double rating;
  final int totalDeliveries;
  final DateTime joinDate;
  final String status;
  final VehicleInfo? vehicle;
  final bool isVerified;
  final String preferredLanguage;
  final EmergencyContact? emergencyContact;

  DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.city,
    required this.vehicleType,
    required this.licenseNumber,
    required this.nationalId,
    required this.rating,
    required this.totalDeliveries,
    required this.joinDate,
    required this.status,
    this.vehicle,
    required this.isVerified,
    required this.preferredLanguage,
    this.emergencyContact,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      city: json['city'] ?? '',
      vehicleType:
          json['vehicle_type'] ??
          (json['vehicleInfo'] != null
              ? json['vehicleInfo']['type'] ?? ''
              : ''),
      licenseNumber: json['license_number'] ?? '',
      nationalId: json['national_id'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalDeliveries: json['total_deliveries'] ?? json['totalDeliveries'] ?? 0,
      joinDate: DateTime.parse(
        json['join_date'] ??
            json['joinDate'] ??
            DateTime.now().toIso8601String(),
      ),
      status: json['status'] ?? 'active',
      vehicle: json['vehicle'] != null
          ? VehicleInfo.fromJson(json['vehicle'])
          : (json['vehicleInfo'] != null
                ? VehicleInfo.fromJson(json['vehicleInfo'])
                : null),
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      preferredLanguage: json['preferred_language'] ?? 'ar',
      emergencyContact: json['emergency_contact'] != null
          ? EmergencyContact.fromJson(json['emergency_contact'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'city': city,
      'vehicle_type': vehicleType,
      'license_number': licenseNumber,
      'national_id': nationalId,
      'rating': rating,
      'total_deliveries': totalDeliveries,
      'join_date': joinDate.toIso8601String(),
      'status': status,
      'vehicle': vehicle?.toJson(),
      'is_verified': isVerified,
      'preferred_language': preferredLanguage,
      'emergency_contact': emergencyContact?.toJson(),
    };
  }

  DriverProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? city,
    String? vehicleType,
    String? licenseNumber,
    String? nationalId,
    double? rating,
    int? totalDeliveries,
    DateTime? joinDate,
    String? status,
    VehicleInfo? vehicle,
    bool? isVerified,
    String? preferredLanguage,
    EmergencyContact? emergencyContact,
  }) {
    return DriverProfile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      vehicleType: vehicleType ?? this.vehicleType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      nationalId: nationalId ?? this.nationalId,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      vehicle: vehicle ?? this.vehicle,
      isVerified: isVerified ?? this.isVerified,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}

class VehicleInfo {
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final String color;
  final String type; // motorcycle, car, bicycle
  final bool hasInsurance;
  final DateTime? insuranceExpiry;

  VehicleInfo({
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.color,
    required this.type,
    required this.hasInsurance,
    this.insuranceExpiry,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 0,
      licensePlate: json['license_plate'] ?? json['plateNumber'] ?? '',
      color: json['color'] ?? '',
      type: json['type'] ?? '',
      hasInsurance: json['has_insurance'] ?? true,
      insuranceExpiry: json['insurance_expiry'] != null
          ? DateTime.parse(json['insurance_expiry'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'color': color,
      'type': type,
      'has_insurance': hasInsurance,
      'insurance_expiry': insuranceExpiry?.toIso8601String(),
    };
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'phone': phone, 'relationship': relationship};
  }
}
