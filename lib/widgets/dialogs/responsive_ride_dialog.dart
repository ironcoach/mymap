import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/models/ride_data.dart';

class ResponsiveRideDialog extends StatefulWidget {
  final LatLng location;
  final bool isEdit;
  final Ride? existingRide;
  final Future<void> Function(Ride ride, bool isEdit) onSave;
  final VoidCallback onCancel;

  // Internal method to check if form has been modified

  const ResponsiveRideDialog({
    super.key,
    required this.location,
    required this.isEdit,
    this.existingRide,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ResponsiveRideDialog> createState() => _ResponsiveRideDialogState();
}

class _ResponsiveRideDialogState extends State<ResponsiveRideDialog>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;
  
  int _currentStep = 0;
  final int _totalSteps = 3;
  bool _isLoading = false;
  
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
  late TextEditingController externalRouteController;

  // Form state
  RideType selectedRideType = RideType.roadRide;
  RideDifficulty selectedDifficulty = RideDifficulty.moderate;
  DayOfWeekType selectedDow = DayOfWeekType.monday;
  TimeOfDay selectedTime = const TimeOfDay(hour: 17, minute: 0); // 5:00 PM
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
    distanceController = TextEditingController(text: '0');
    externalRouteController = TextEditingController();
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
      externalRouteController.text = ride.rideWithGpsUrl ?? ride.stravaUrl ?? '';
      selectedRideType = ride.rideType ?? RideType.roadRide;
      selectedDifficulty = ride.difficulty ?? RideDifficulty.moderate;
      selectedDow = ride.dow ?? DayOfWeekType.monday;
      selectedTime = ride.startTime != null
        ? TimeOfDay.fromDateTime(ride.startTime!)
        : TimeOfDay.now();
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
    externalRouteController.dispose();
    super.dispose();
  }

  // Responsive breakpoints
  bool get isWeb => kIsWeb;
  bool get isDesktop => MediaQuery.of(context).size.width > 1200;
  bool get isTablet => MediaQuery.of(context).size.width > 600 && 
                      MediaQuery.of(context).size.width <= 1200;
  bool get isMobile => MediaQuery.of(context).size.width <= 600;

  double get dialogWidth {
    if (isDesktop) return 600;
    if (isTablet) return MediaQuery.of(context).size.width * 0.8;
    return MediaQuery.of(context).size.width * 0.95;
  }

  double get dialogHeight {
    if (isDesktop) return 700;
    if (isTablet) return MediaQuery.of(context).size.height * 0.85;
    return MediaQuery.of(context).size.height * 0.9;
  }

  void _nextStep() {
    if (_validateCurrentStep() && _currentStep < _totalSteps - 1) {
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
        if (titleController.text.trim().isEmpty) {
          _showErrorMessage('Ride title is required');
          return false;
        }
        return true;
      case 1: // Schedule
        return true; // Schedule always valid with defaults
      case 2: // Contact
        if (contactController.text.trim().isEmpty) {
          _showErrorMessage('Contact name is required');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  bool _hasUnsavedChanges() {
    // Check if any field has been modified from initial state
    if (widget.isEdit && widget.existingRide != null) {
      final ride = widget.existingRide!;
      return titleController.text.trim() != (ride.title ?? '') ||
             descController.text.trim() != (ride.desc ?? '') ||
             snippetController.text.trim() != (ride.snippet ?? '') ||
             startPointController.text.trim() != (ride.startPointDesc ?? '') ||
             contactController.text.trim() != (ride.contact ?? '') ||
             phoneController.text.trim() != (ride.phone ?? '') ||
             distanceController.text.trim() != (ride.rideDistance?.toString() ?? '0') ||
             externalRouteController.text.trim() != (ride.rideWithGpsUrl ?? ride.stravaUrl ?? '') ||
             selectedRideType != (ride.rideType ?? RideType.roadRide) ||
             selectedDifficulty != (ride.difficulty ?? RideDifficulty.moderate) ||
             selectedDow != (ride.dow ?? DayOfWeekType.monday);
    } else {
      // For new rides, check if any field has content
      return titleController.text.trim().isNotEmpty ||
             descController.text.trim().isNotEmpty ||
             snippetController.text.trim().isNotEmpty ||
             startPointController.text.trim().isNotEmpty ||
             contactController.text.trim().isNotEmpty ||
             phoneController.text.trim().isNotEmpty ||
             externalRouteController.text.trim().isNotEmpty ||
             (distanceController.text.trim() != '0' && distanceController.text.trim().isNotEmpty);
    }
  }

  Future<void> _handleCancel() async {
    debugPrint('Dialog cancel requested');
    
    if (_hasUnsavedChanges()) {
      debugPrint('Unsaved changes detected, showing confirmation');
      final shouldClose = await _showCancelConfirmation();
      if (shouldClose == true) {
        debugPrint('User confirmed cancel with unsaved changes');
        widget.onCancel();
      } else {
        debugPrint('User chose to continue editing');
      }
    } else {
      debugPrint('No unsaved changes, closing dialog');
      widget.onCancel();
    }
  }

  Future<bool?> _showCancelConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to close this dialog?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continue Editing'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handleSave() async {
    debugPrint('=== ResponsiveRideDialog._handleSave called ===');
    
    if (!_validateCurrentStep()) {
      debugPrint('Validation failed, not proceeding with save');
      return;
    }
    
    debugPrint('Validation passed, setting loading state');
    setState(() {
      _isLoading = true;
    });

    try {
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
        difficulty: selectedDifficulty,
        rideWithGpsUrl: externalRouteController.text.trim().isEmpty ? null : externalRouteController.text.trim(),
      );
      
      debugPrint('Created ride object: ${ride.title}');
      debugPrint('Calling widget.onSave callback...');

      // Call the save callback and await it
      await widget.onSave(ride, widget.isEdit);
      debugPrint('widget.onSave callback completed');

      // Close the dialog after saving
      if (mounted && Navigator.canPop(context)) {
        debugPrint('Dialog closing itself...');
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      debugPrint('Error in dialog _handleSave: $e');

      // Show error to user and don't close dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save ride: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        debugPrint('Resetting loading state');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Always intercept dismissal attempts to check for unsaved changes
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && mounted) {
          // Handle all dismissal attempts (back button, barrier tap, etc.)
          if (_hasUnsavedChanges()) {
            debugPrint('Dismissal blocked: unsaved changes detected');
            final navigator = Navigator.of(context);
            final shouldClose = await _showCancelConfirmation();
            if (shouldClose == true && mounted) {
              debugPrint('User confirmed dismissal with unsaved changes');
              navigator.pop();
            } else {
              debugPrint('User chose to continue editing');
            }
          } else {
            debugPrint('No unsaved changes, allowing dismissal');
            Navigator.of(context).pop();
          }
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: const BoxConstraints(
          minWidth: 300,
          maxWidth: 600,
          minHeight: 400,
          maxHeight: 800,
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(child: _buildContent()),
            _buildNavigationButtons(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.directions_bike, 
            color: Theme.of(context).primaryColor,
            size: isDesktop ? 32 : 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isEdit ? 'Edit Ride' : 'Create New Ride',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 24 : 20,
              ),
            ),
          ),
          IconButton(
            onPressed: _handleCancel,
            icon: const Icon(Icons.close),
            iconSize: isDesktop ? 24 : 20,
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (isMobile) {
      // Mobile: Simple step indicator
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Tablet/Desktop: Tab-style indicator
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          onTap: (index) {
            // Allow jumping to previous steps, but validate current step first
            if (index < _currentStep || _validateCurrentStep()) {
              setState(() {
                _currentStep = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          tabs: const [
            Tab(text: 'Basic Info', icon: Icon(Icons.info_outline, size: 16)),
            Tab(text: 'Schedule', icon: Icon(Icons.schedule, size: 16)),
            Tab(text: 'Contact', icon: Icon(Icons.contact_phone, size: 16)),
          ],
        ),
      );
    }
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (!_validateCurrentStep() && index > _currentStep) {
            // Don't allow moving forward if current step is invalid
            _pageController.animateToPage(
              _currentStep,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
            return;
          }
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Tell us about your ride', Icons.info_outline),
          SizedBox(height: isDesktop ? 24 : 16),
          _buildTextField(
            controller: titleController,
            label: 'Ride Title',
            hint: 'e.g., Morning Coffee Ride',
            required: true,
            autofocus: !isWeb, // Don't autofocus on web to prevent keyboard popup
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: descController,
            label: 'Description',
            hint: 'Describe your ride...',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: snippetController,
            label: 'Short Summary',
            hint: 'Brief description for map',
          ),
          const SizedBox(height: 16),
          _buildRideTypeDropdown(),
          const SizedBox(height: 16),
          _buildDifficultyDropdown(),
          const SizedBox(height: 16),
          if (isDesktop) const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScheduleStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('When does it happen?', Icons.schedule),
          SizedBox(height: isDesktop ? 24 : 16),
          _buildDayOfWeekDropdown(),
          const SizedBox(height: 16),
          _buildTimeSelector(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: distanceController,
                  label: 'Distance',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'miles',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: startPointController,
            label: 'Starting Point',
            hint: 'Where does the ride begin?',
          ),
          const SizedBox(height: 24),
          Text(
            'External Route Links (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isDesktop ? 18 : 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Link to external route services for detailed route information',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: externalRouteController,
            label: 'External Route URL',
            hint: 'https://ridewithgps.com/routes/... or Strava link',
            keyboardType: TextInputType.url,
          ),
          if (isDesktop) const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContactStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Contact Information', Icons.contact_phone),
          SizedBox(height: isDesktop ? 24 : 16),
          _buildTextField(
            controller: contactController,
            label: 'Contact Name',
            hint: 'Ride leader name',
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: phoneController,
            label: 'Phone Number',
            hint: 'Optional',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          _buildLocationDisplay(),
          if (isDesktop) const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon, 
          size: isDesktop ? 24 : 20, 
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isDesktop ? 22 : 18,
            ),
          ),
        ),
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
    bool autofocus = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      autofocus: autofocus,
      style: TextStyle(fontSize: isDesktop ? 16 : 14),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: isDesktop ? 16 : 12,
        ),
        errorStyle: TextStyle(fontSize: isDesktop ? 14 : 12),
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
      initialValue: selectedRideType,
      style: TextStyle(
        fontSize: isDesktop ? 16 : 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: 'Ride Type',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: isDesktop ? 16 : 12,
        ),
      ),
      items: RideType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(_getRideTypeIcon(type), size: isDesktop ? 24 : 20),
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

  Widget _buildDifficultyDropdown() {
    return DropdownButtonFormField<RideDifficulty>(
      initialValue: selectedDifficulty,
      style: TextStyle(
        fontSize: isDesktop ? 16 : 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: 'Difficulty Level',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isDesktop ? 16 : 12,
        ),
      ),
      items: RideDifficulty.values.map((difficulty) {
        return DropdownMenuItem(
          value: difficulty,
          child: Text(difficulty.titleName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedDifficulty = value!;
        });
      },
    );
  }


  Widget _buildDayOfWeekDropdown() {
    return DropdownButtonFormField<DayOfWeekType>(
      initialValue: selectedDow,
      style: TextStyle(
        fontSize: isDesktop ? 16 : 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: 'Day of Week',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isDesktop ? 16 : 12,
        ),
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
        padding: EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: isDesktop ? 18 : 16,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time, 
              color: Theme.of(context).primaryColor,
              size: isDesktop ? 24 : 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Start Time: ${selectedTime.format(context)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: isDesktop ? 16 : 14,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: isDesktop ? 24 : 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDisplay() {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on, 
                color: Theme.of(context).colorScheme.primary, 
                size: isDesktop ? 24 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ride Location',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 12 : 8),
          Text(
            'Latitude: ${widget.location.latitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
          Text(
            'Longitude: ${widget.location.longitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 16 : 12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: isDesktop ? 20 : 16),
                    const SizedBox(width: 8),
                    const Text('Back'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ] else ...[
            // Cancel button for the first step
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _handleCancel,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 16 : 12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: isDesktop ? 20 : 16),
                    const SizedBox(width: 8),
                    const Text('Cancel'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (
                _currentStep == _totalSteps - 1 ? _handleSave : _nextStep
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 16 : 12,
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: isDesktop ? 20 : 16,
                      width: isDesktop ? 20 : 16,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentStep == _totalSteps - 1 
                            ? (widget.isEdit ? 'Update Ride' : 'Create Ride')
                            : 'Next'),
                        if (_currentStep < _totalSteps - 1) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: isDesktop ? 20 : 16),
                        ],
                      ],
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
    if (Theme.of(context).platform == TargetPlatform.iOS && !isWeb) {
      // iOS native time picker
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
                selectedDT = newTime;
              });
            },
          ),
        ),
      );
    } else {
      // Material time picker (Android and Web)
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(isDesktop ? 1.1 : 1.0),
            ),
            child: child!,
          );
        },
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