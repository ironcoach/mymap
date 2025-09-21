import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/utils/extensions.dart';
import 'package:mymap/widgets/my_textfield.dart';

class RideDialog extends StatefulWidget {
  final LatLng location;
  final bool isEdit;
  final Ride? existingRide;
  final Future<void> Function(Ride ride, bool isEdit) onSave;
  final VoidCallback onCancel;

  const RideDialog({
    super.key,
    required this.location,
    required this.isEdit,
    this.existingRide,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<RideDialog> createState() => _RideDialogState();
}

class _RideDialogState extends State<RideDialog> {
  late TextEditingController titleController;
  late TextEditingController descController;
  late TextEditingController snippetController;
  late TextEditingController startPointController;
  late TextEditingController contactController;
  late TextEditingController phoneController;
  late TextEditingController distanceController;
  late TextEditingController externalRouteController;

  RideType selectedRideType = RideType.roadRide;
  RideDifficulty selectedDifficulty = RideDifficulty.moderate;
  DayOfWeekType selectedDow = DayOfWeekType.monday;
  TimeOfDay selectedTime = const TimeOfDay(hour: 17, minute: 0); // 5:00 PM
  DateTime selectedDT = DateTime.now();

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
    distanceController = TextEditingController();
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
      externalRouteController.text = ride.routeUrl ?? '';
      selectedRideType = ride.rideType ?? RideType.roadRide;
      selectedDifficulty = ride.difficulty ?? RideDifficulty.moderate;
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

  Future<void> _selectTime(BuildContext context) async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext builder) => SizedBox(
          height: 216,
          child: CupertinoDatePicker(
            backgroundColor: context.colorScheme.surfaceContainerHighest,
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
      await showTimePicker(
        context: context,
        initialTime: selectedTime,
      ).then((value) {
        if (value != null) {
          setState(() {
            selectedDT = DateTime(selectedDT.year, selectedDT.month,
                selectedDT.day, value.hour, value.minute);
            selectedTime = TimeOfDay.fromDateTime(selectedDT);
          });
        }
      });
    }
  }

  Future<void> _handleSave() async {
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
        routeUrl: externalRouteController.text.trim().isEmpty ? null : externalRouteController.text.trim(),
      );

      await widget.onSave(ride, widget.isEdit);

      // Close dialog after save completes
      if (mounted) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colorScheme.onTertiary,
      title: Text(widget.isEdit ? "Edit Ride Details" : "Add a new Ride"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                children: [
              MyTextField(
                controller: titleController,
                hintText: "Ride Title",
                obscureText: false,
              ),
              MyTextField(
                controller: descController,
                hintText: "Ride Description",
                obscureText: false,
              ),
              MyTextField(
                controller: snippetController,
                hintText: "Info Window Snippet",
                obscureText: false,
              ),
              _buildDayOfWeekDropdown(setState),
              _buildTimeSelector(setState),
              _buildRideTypeDropdown(setState),
              _buildDifficultyDropdown(setState),
              MyTextField(
                controller: distanceController,
                hintText: "Distance (miles)",
                obscureText: false,
              ),
              MyTextField(
                controller: startPointController,
                hintText: "Starting Point Description",
                obscureText: false,
              ),
              MyTextField(
                controller: contactController,
                hintText: "Contact Name",
                obscureText: false,
              ),
              MyTextField(
                controller: phoneController,
                hintText: "Contact Phone",
                obscureText: false,
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'External Route Link (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              MyTextField(
                controller: externalRouteController,
                hintText: "GPS Route URL (RideWithGPS, Strava, etc.)",
                obscureText: false,
              ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        _buildCancelButton(),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildDayOfWeekDropdown(StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: DropdownButtonFormField<DayOfWeekType>(
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colorScheme.outline),
          ),
          fillColor: context.colorScheme.onInverseSurface,
          filled: true,
        ),
        dropdownColor: context.colorScheme.onInverseSurface,
        initialValue: selectedDow,
        onChanged: (newDay) {
          setState(() {
            selectedDow = newDay!;
          });
        },
        items: DayOfWeekType.values.map((DayOfWeekType type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type.titleName),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeSelector(StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: context.colorScheme.outlineVariant),
          color: context.colorScheme.onInverseSurface,
        ),
        child: GestureDetector(
          onTap: () async {
            await _selectTime(context).then((value) {
              setState(() {});
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  '${selectedTime.hourOfPeriod}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: Icon(IconData(0xe662, fontFamily: 'MaterialIcons')),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideTypeDropdown(StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: DropdownButtonFormField<RideType>(
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colorScheme.outline),
          ),
          fillColor: context.colorScheme.onInverseSurface,
          filled: true,
          labelText: 'Ride Type',
        ),
        dropdownColor: context.colorScheme.onInverseSurface,
        initialValue: selectedRideType,
        onChanged: (newRideType) {
          setState(() {
            selectedRideType = newRideType!;
          });
        },
        items: RideType.values.map((RideType type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type.titleName),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDifficultyDropdown(StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: DropdownButtonFormField<RideDifficulty>(
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.colorScheme.outline),
          ),
          fillColor: context.colorScheme.onInverseSurface,
          filled: true,
          labelText: 'Difficulty Level',
        ),
        dropdownColor: context.colorScheme.onInverseSurface,
        initialValue: selectedDifficulty,
        onChanged: (newDifficulty) {
          setState(() {
            selectedDifficulty = newDifficulty!;
          });
        },
        items: RideDifficulty.values.map((RideDifficulty difficulty) {
          return DropdownMenuItem(
            value: difficulty,
            child: Text(difficulty.titleName),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildCancelButton() {
    return TextButton(
      onPressed: widget.onCancel,
      child: const Text('Cancel'),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _handleSave,
      child: const Text('Save'),
    );
  }
}
