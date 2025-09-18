import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/utils/extensions.dart';
import 'package:mymap/widgets/my_textfield.dart';

class ImprovedRideDialog extends StatefulWidget {
  final LatLng location;
  final bool isEdit;
  final Ride? existingRide;
  final Function(Ride ride, bool isEdit) onSave;
  final VoidCallback onCancel;

  const ImprovedRideDialog({
    super.key,
    required this.location,
    required this.isEdit,
    this.existingRide,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ImprovedRideDialog> createState() => _ImprovedRideDialogState();
}

class _ImprovedRideDialogState extends State<ImprovedRideDialog>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;
  
  int _currentStep = 0;
  final int _totalSteps = 3;
  
  // Form key for validation
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
  DateTime selectedDT = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: _totalSteps, vsync: this);
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
    distanceController = TextEditingController();
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
    } else {
      distanceController.text = '0';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    titleController.dispose();
    descController.dispose();
    snippetController.dispose();
    startPointController.dispose();
    contactController.dispose();
    phoneController.dispose();
    distanceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _tabController.animateTo(_currentStep);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _tabController.animateTo(_currentStep);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic Info
        return titleController.text.trim().isNotEmpty;
      case 1: // Schedule
        return true; // Schedule always valid with defaults
      case 2: // Contact
        return contactController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    
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
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(child: _buildContent()),
            _buildNavigationButtons(),
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
          Icon(Icons.directions_bike, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isEdit ? 'Edit Ride' : 'Create New Ride',
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

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(),
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Basic', icon: Icon(Icons.info_outline, size: 16)),
                Tab(text: 'Schedule', icon: Icon(Icons.schedule, size: 16)),
                Tab(text: 'Contact', icon: Icon(Icons.contact_phone, size: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentStep = index;
          });
          _tabController.animateTo(index);
        },
        children: [
          _buildBasicInfoStep(),
          _buildScheduleStep(),
          _buildContactStep(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your ride',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Ride Title *',
              hintText: 'e.g., Morning Coffee Ride',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Ride title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe your ride...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: snippetController,
            decoration: const InputDecoration(
              labelText: 'Short Summary',
              hintText: 'Brief description for map',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<RideType>(
            value: selectedRideType,
            decoration: const InputDecoration(
              labelText: 'Ride Type',
              border: OutlineInputBorder(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When does it happen?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<DayOfWeekType>(
            value: selectedDow,
            decoration: const InputDecoration(
              labelText: 'Day of Week',
              border: OutlineInputBorder(),
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
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectTime(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule),
                  const SizedBox(width: 12),
                  Text(
                    'Start Time: ${selectedTime.format(context)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: distanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Distance (miles)',
              hintText: '0',
              border: OutlineInputBorder(),
              suffixText: 'miles',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: startPointController,
            decoration: const InputDecoration(
              labelText: 'Starting Point',
              hintText: 'Where does the ride begin?',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: contactController,
            decoration: const InputDecoration(
              labelText: 'Contact Name *',
              hintText: 'Ride leader name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Contact name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Optional',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Location',
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
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1
                  ? _handleSave
                  : (_validateCurrentStep() ? _nextStep : null),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Save Ride' : 'Next',
              ),
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
        builder: (BuildContext builder) => SizedBox(
          height: 216,
          child: CupertinoDatePicker(
            backgroundColor: Theme.of(context).cardColor,
            initialDateTime: selectedDT,
            mode: CupertinoDatePickerMode.time,
            onDateTimeChanged: (DateTime newTime) {
              setState(() {
                selectedDT = newTime;
                selectedTime = TimeOfDay.fromDateTime(selectedDT);
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
          selectedDT = DateTime(selectedDT.year, selectedDT.month,
              selectedDT.day, picked.hour, picked.minute);
        });
      }
    }
  }
}