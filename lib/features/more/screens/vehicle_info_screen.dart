import 'package:flutter/material.dart';
import '../../../app_colors.dart';
import '../../../models/driver_profile.dart';
import '../../../services/driver_service.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  VehicleInfo? _vehicleInfo;
  bool _isLoading = true;
  bool _isEditing = false;

  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _colorController = TextEditingController();
  String? _selectedType;

  final List<String> _vehicleTypes = ['motorcycle', 'car', 'bicycle'];

  @override
  void initState() {
    super.initState();
    _loadVehicleInfo();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleInfo() async {
    try {
      final profile = await DriverService.getDriverProfile();
      if (profile?.vehicle != null) {
        setState(() {
          _vehicleInfo = profile!.vehicle!;
          _makeController.text = _vehicleInfo!.make;
          _modelController.text = _vehicleInfo!.model;
          _yearController.text = _vehicleInfo!.year.toString();
          _licensePlateController.text = _vehicleInfo!.licensePlate;
          _colorController.text = _vehicleInfo!.color;
          _selectedType = _vehicleInfo!.type;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isEditing = true; // Start in editing mode if no vehicle info
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading vehicle info: $e');
    }
  }

  Future<void> _saveVehicleInfo() async {
    if (_selectedType == null) {
      _showErrorSnackBar('Please select a vehicle type');
      return;
    }

    try {
      final vehicleInfo = VehicleInfo(
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        licensePlate: _licensePlateController.text.trim(),
        color: _colorController.text.trim(),
        type: _selectedType!,
        hasInsurance: _vehicleInfo?.hasInsurance ?? false,
        insuranceExpiry: _vehicleInfo?.insuranceExpiry,
      );

      final success = await DriverService.updateVehicleInfo(vehicleInfo);

      if (success) {
        setState(() {
          _vehicleInfo = vehicleInfo;
          _isEditing = false;
        });
        _showSuccessSnackBar('Vehicle information updated successfully');
      } else {
        _showErrorSnackBar('Failed to update vehicle information');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating vehicle info: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Vehicle Information',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveVehicleInfo,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (_vehicleInfo != null)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Vehicle Image/Icon Section
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getVehicleIcon(
                              _selectedType ?? _vehicleInfo?.type,
                            ),
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _vehicleInfo != null
                              ? '${_vehicleInfo!.year} ${_vehicleInfo!.make} ${_vehicleInfo!.model}'
                              : 'Add Vehicle Information',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_vehicleInfo != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _vehicleInfo!.licensePlate,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Vehicle Details Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicle Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Vehicle Type Selector
                        if (_isEditing) ...[
                          const Text(
                            'Vehicle Type',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedType,
                                hint: const Text('Select vehicle type'),
                                isExpanded: true,
                                items: _vehicleTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Row(
                                      children: [
                                        Icon(_getVehicleIcon(type), size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          type.isNotEmpty
                                              ? type[0].toUpperCase() + type.substring(1)
                                              : type,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (_vehicleInfo != null) ...[
                          _buildStaticInfoField(
                            label: 'Vehicle Type',
                            value:
                                _vehicleInfo!.type.isNotEmpty
                                    ? _vehicleInfo!.type[0].toUpperCase() + _vehicleInfo!.type.substring(1)
                                    : _vehicleInfo!.type,
                            icon: _getVehicleIcon(_vehicleInfo!.type),
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildFormField(
                          label: 'Make',
                          controller: _makeController,
                          icon: Icons.business,
                          isEditable: _isEditing,
                        ),

                        const SizedBox(height: 16),

                        _buildFormField(
                          label: 'Model',
                          controller: _modelController,
                          icon: Icons.directions_car,
                          isEditable: _isEditing,
                        ),

                        const SizedBox(height: 16),

                        _buildFormField(
                          label: 'Year',
                          controller: _yearController,
                          icon: Icons.calendar_today,
                          isEditable: _isEditing,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        _buildFormField(
                          label: 'License Plate',
                          controller: _licensePlateController,
                          icon: Icons.confirmation_number,
                          isEditable: _isEditing,
                        ),

                        const SizedBox(height: 16),

                        _buildFormField(
                          label: 'Color',
                          controller: _colorController,
                          icon: Icons.palette,
                          isEditable: _isEditing,
                        ),
                      ],
                    ),
                  ),

                  if (_vehicleInfo != null) ...[
                    const SizedBox(height: 20),

                    // Insurance Status
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Insurance Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                _vehicleInfo!.hasInsurance
                                    ? Icons.verified_user
                                    : Icons.warning,
                                color: _vehicleInfo!.hasInsurance
                                    ? AppColors.success
                                    : AppColors.warning,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _vehicleInfo!.hasInsurance
                                          ? 'Insured'
                                          : 'Not Insured',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _vehicleInfo!.hasInsurance
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    ),
                                    if (_vehicleInfo!.hasInsurance &&
                                        _vehicleInfo!.insuranceExpiry != null)
                                      Text(
                                        'Expires: ${_vehicleInfo!.insuranceExpiry!.day}/${_vehicleInfo!.insuranceExpiry!.month}/${_vehicleInfo!.insuranceExpiry!.year}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  IconData _getVehicleIcon(String? type) {
    switch (type) {
      case 'motorcycle':
        return Icons.motorcycle;
      case 'car':
        return Icons.directions_car;
      case 'bicycle':
        return Icons.pedal_bike;
      default:
        return Icons.directions_car;
    }
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditable,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isEditable ? AppColors.primary : AppColors.grey300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            enabled: isEditable,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
