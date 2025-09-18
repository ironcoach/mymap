import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/utils/extensions.dart';

class SectionedRideDialog extends StatefulWidget {
  final LatLng location;
  final bool isEdit;
  final Ride? existingRide;
  final Function(Ride ride, bool isEdit) onSave;
  final VoidCallback onCancel;

  const SectionedRideDialog({
    super.key,
    required this.location,
    required this.isEdit,
    this.existingRide,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<SectionedRideDialog> createState() => _SectionedRideDialogState();
}

class _SectionedRideDialogState extends State<SectionedRideDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController titleController;
  late TextEditingController descController;
  late TextEditingController snippetController;
  late TextEditingController startPointController;
  late TextEditingController contactController;
  late TextEditingController phoneController;
  late TextEditingController distanceController;

  // Form state
  RideType selectedRideType = RideType.roadRide;
  DayOfWeekType selectedDow = DayOfWeekType.monday;
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingData();
  }

  void _initializeControllers() {
    titleController = TextEditingController();
    descController = TextEditingController();
    snippetController = TextEditingController();
    startPointController = TextEditingController();
    contactController = TextEditingController();
    phoneController = TextEditingController();
    distanceController = TextEditingController(text: '0');
  }

  void _loadExistingData() {
    if (widget.isEdit && widget.existingRide != null) {
      final ride = widget.existingRide!;
      titleController.text = ride.title ?? '';
      descController.text = ride.desc ?? '';
      snippetController.text = ride.snippet ?? '';
      startPointController.text = ride.startPointDesc ?? '';
      contactController.text = ride.contact ?? '';
      phoneController.text = ride.phone ?? '';
      distanceController.text = ride.rideDistance?.toString() ?? '0';
      selectedRideType = ride.rideType ?? RideType.roadRide;
      selectedDow = ride.dow ?? DayOfWeekType.monday;
      selectedTime = ride.startTime != null 
        ? TimeOfDay.fromDateTime(ride.startTime!) 
        : TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    snippetController.dispose();
    startPointController.dispose();
    contactController.dispose();
    phoneController.dispose();
    distanceController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    
    final ride = Ride(
      title: titleController.text.trim(),
      desc: descController.text.trim(),
      snippet: snippetController.text.trim(),
      dow: selectedDow,
      startTime: DateTime(DateTime.now().year, DateTime.now().month,
          DateTime.now().day, selectedTime.hour, selectedTime.minute),
      startPointDesc: startPointController.text.trim(),
      contact: contactController.text.trim(),
      phone: phoneController.text.trim(),
      latlng: widget.location,
      verified: false,
      rideType: selectedRideType,
      rideDistance: int.tryParse(distanceController.text.trim()) ?? 0,
    );
    
    widget.onSave(ride, widget.isEdit);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSection(
                        'Basic Information',
                        Icons.info_outline,
                        [
                          _buildTextField(
                            controller: titleController,
                            label: 'Ride Title',
                            hint: 'e.g., Morning Coffee Ride',
                            required: true,
                          ),
                          _buildTextField(
                            controller: descController,
                            label: 'Description',
                            hint: 'Tell us about your ride...',
                            maxLines: 3,
                          ),
                          _buildTextField(
                            controller: snippetController,
                            label: 'Short Summary',
                            hint: 'Brief description for map',
                          ),
                          _buildRideTypeDropdown(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        'Schedule',
                        Icons.schedule,
                        [
                          _buildDayOfWeekDropdown(),
                          _buildTimeSelector(),
                          _buildTextField(
                            controller: distanceController,
                            label: 'Distance (miles)',
                            hint: '0',
                            keyboardType: TextInputType.number,
                            suffixText: 'miles',
                          ),
                          _buildTextField(
                            controller: startPointController,
                            label: 'Starting Point',
                            hint: 'Where does the ride begin?',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        'Contact',
                        Icons.contact_phone,
                        [
                          _buildTextField(
                            controller: contactController,
                            label: 'Contact Name',
                            hint: 'Ride leader name',
                            required: true,
                          ),
                          _buildTextField(
                            controller: phoneController,
                            label: 'Phone Number',
                            hint: 'Optional',
                            keyboardType: TextInputType.phone,
                          ),
                          _buildLocationDisplay(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bike, 
               color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isEdit ? 'Edit Ride Details' : 'Create New Ride',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: child,
        )),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        suffixText: suffixText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: required ? (value) {
        if (value?.trim().isEmpty ?? true) {
          return '$label is required';
        }
        return null;
      } : null,
    );
  }

  Widget _buildRideTypeDropdown() {
    return DropdownButtonFormField<RideType>(
      value: selectedRideType,
      decoration: const InputDecoration(
        labelText: 'Ride Type',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: RideType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(_getRideTypeIcon(type), size: 20),
              const SizedBox(width: 8),
              Text(type.titleName),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedRideType = value!;
        });
      },
    );
  }

  Widget _buildDayOfWeekDropdown() {
    return DropdownButtonFormField<DayOfWeekType>(
      value: selectedDow,
      decoration: const InputDecoration(
        labelText: 'Day of Week',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: DayOfWeekType.values.map((day) {
        return DropdownMenuItem(
          value: day,
          child: Text(day.titleName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedDow = value!;
        });
      },
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: () => _selectTime(context),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(
              'Start Time: ${selectedTime.format(context)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ride Location',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lat: ${widget.location.latitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Lng: ${widget.location.longitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(widget.isEdit ? 'Update Ride' : 'Create Ride'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRideTypeIcon(RideType type) {
    switch (type) {
      case RideType.roadRide:
        return Icons.directions_bike;
      case RideType.gravelRide:
        return Icons.terrain;
      case RideType.mtbRide:
        return Icons.forest;
      case RideType.bikeEvent:
        return Icons.event;
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext builder) => Container(
          height: 216,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: CupertinoDatePicker(
            initialDateTime: DateTime(2023, 1, 1, selectedTime.hour, selectedTime.minute),
            mode: CupertinoDatePickerMode.time,
            onDateTimeChanged: (DateTime newTime) {
              setState(() {
                selectedTime = TimeOfDay.fromDateTime(newTime);
              });
            },
          ),
        ),
      );
    } else {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );
      if (picked != null) {
        setState(() {
          selectedTime = picked;
        });
      }
    }
  }
}