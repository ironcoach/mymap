import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/widgets/ride_widgets.dart';
import 'package:mymap/repositories/ride_repository.dart';

/// Dialog for displaying ride information with quality indicators and actions
class RideInfoDialog extends ConsumerWidget {
  final Ride ride;
  final String rideId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RideInfoDialog({
    super.key,
    required this.ride,
    required this.rideId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 1200;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isDesktop ? 600 : MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, theme),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfo(context, theme),
                    const SizedBox(height: 24),
                    _buildRatingAndDifficulty(context, theme),
                    const SizedBox(height: 24),
                    _buildUserRatingSection(context, theme, ref),
                    const SizedBox(height: 24),
                    RideQualityIndicators(
                      ride: ride,
                      rideId: rideId,
                      compact: false,
                    ),
                    const SizedBox(height: 24),
                    _buildScheduleInfo(context, theme),
                    const SizedBox(height: 24),
                    _buildLocationInfo(context, theme),
                    if (ride.contact?.isNotEmpty == true) ...[
                      const SizedBox(height: 24),
                      _buildContactInfo(context, theme),
                    ],
                  ],
                ),
              ),
            ),
            _buildActionButtons(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            _getRideTypeIcon(ride.rideType ?? RideType.roadRide),
            color: theme.colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.title ?? 'Untitled Ride',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (ride.rideType != null)
                  Text(
                    ride.rideType!.titleName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ride.desc?.isNotEmpty == true) ...[
          Text(
            'Description',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ride.desc!,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        if (ride.snippet?.isNotEmpty == true) ...[
          Text(
            'Quick Info',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              ride.snippet!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingAndDifficulty(BuildContext context, ThemeData theme) {
    if ((ride.averageRating == null || ride.averageRating! <= 0) &&
        ride.difficulty == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Rating & Difficulty',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rating display
          if (ride.averageRating != null && ride.averageRating! > 0) ...[
            Row(
              children: [
                StarRating(
                  rating: ride.averageRating!,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  ride.ratingDisplayText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (ride.difficulty != null) const SizedBox(height: 8),
          ],

          // Difficulty display
          if (ride.difficulty != null) ...[
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                DifficultyChip(
                  difficulty: ride.difficulty!,
                  showDescription: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserRatingSection(BuildContext context, ThemeData theme, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserRating = currentUser != null
        ? (ride.userRatings?[currentUser.uid] ?? 0)
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rate_review,
                color: theme.colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Rate This Ride',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentUser == null
                ? 'Log in to rate this ride'
                : currentUserRating > 0
                    ? 'Your rating: $currentUserRating star${currentUserRating == 1 ? '' : 's'}'
                    : 'Tap to rate this ride',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(5, (index) {
                return GestureDetector(
                  onTap: currentUser != null
                      ? () => _handleUserRating(context, ref, index + 1, currentUserRating)
                      : () => _handleUserRating(context, ref, index + 1, currentUserRating),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      currentUserRating > index ? Icons.star : Icons.star_border,
                      color: currentUser == null
                          ? Colors.grey.withValues(alpha: 0.5)
                          : currentUserRating > index
                              ? Colors.amber
                              : Colors.grey,
                      size: 32,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 16),
              if (currentUser != null && currentUserRating > 0)
                TextButton(
                  onPressed: () => _handleUserRating(context, ref, 0, currentUserRating),
                  child: Text(
                    'Remove Rating',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          if (currentUser != null && currentUserRating > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Tap a star to change your rating',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ] else if (currentUser == null) ...[
            const SizedBox(height: 8),
            Text(
              'Please log in to rate rides',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleUserRating(BuildContext context, WidgetRef ref, int newRating, int currentRating) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to rate rides'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newRating == currentRating) {
      // User tapped the same rating, do nothing
      return;
    }

    try {
      final repository = RideRepository();

      if (newRating == 0) {
        await repository.removeUserRating(rideId);
      } else {
        await repository.rateRide(rideId, newRating);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newRating == 0
                  ? 'Rating removed successfully'
                  : 'Rated $newRating star${newRating == 1 ? '' : 's'}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rate ride: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  Widget _buildScheduleInfo(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Schedule & Details',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            'Day of Week',
            ride.dow?.titleName ?? 'Not specified',
            Icons.calendar_today,
          ),
          if (ride.startTime != null)
            _buildInfoRow(
              context,
              'Start Time',
              TimeOfDay.fromDateTime(ride.startTime!).format(context),
              Icons.access_time,
            ),
          if (ride.rideDistance != null && ride.rideDistance! > 0)
            _buildInfoRow(
              context,
              'Distance',
              '${ride.rideDistance} miles',
              Icons.straighten,
            ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ride.startPointDesc?.isNotEmpty == true)
            _buildInfoRow(
              context,
              'Starting Point',
              ride.startPointDesc!,
              Icons.play_arrow,
            ),
          if (ride.latlng != null) ...[
            _buildInfoRow(
              context,
              'Coordinates',
              '${ride.latlng!.latitude.toStringAsFixed(6)}, ${ride.latlng!.longitude.toStringAsFixed(6)}',
              Icons.gps_fixed,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_phone,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Contact Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            'Contact',
            ride.contact!,
            Icons.person,
          ),
          if (ride.phone?.isNotEmpty == true)
            _buildInfoRow(
              context,
              'Phone',
              ride.phone!,
              Icons.phone,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Close'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(width: 12),
            if (onEdit != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onEdit?.call();
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (onDelete != null) ...[
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(context, onDelete!);
                },
                icon: Icon(
                  Icons.delete,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Delete Ride',
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Ride'),
          content: Text('Are you sure you want to delete "${ride.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
}