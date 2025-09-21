import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/widgets/ride_widgets.dart';
import 'package:mymap/repositories/ride_repository.dart';

/// Dialog for displaying ride information with quality indicators and actions
class RideInfoDialog extends ConsumerStatefulWidget {
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
  ConsumerState<RideInfoDialog> createState() => _RideInfoDialogState();
}

class _RideInfoDialogState extends ConsumerState<RideInfoDialog> {
  late int _currentUserRating;

  @override
  void initState() {
    super.initState();
    // Initialize with current user rating from the ride
    final currentUser = FirebaseAuth.instance.currentUser;
    _currentUserRating = currentUser != null
        ? (widget.ride.userRatings?[currentUser.uid] ?? 0)
        : 0;
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildUserRatingSection(context, theme),
                    const SizedBox(height: 24),
                    _buildVerificationSection(context, theme),
                    const SizedBox(height: 24),
                    _buildScheduleInfo(context, theme),
                    const SizedBox(height: 24),
                    _buildLocationInfo(context, theme),
                    if (widget.ride.routeUrl?.isNotEmpty == true) ...[
                      const SizedBox(height: 24),
                      _buildRouteUrlSection(context, theme),
                    ],
                    if (widget.ride.contact?.isNotEmpty == true) ...[
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
            _getRideTypeIcon(widget.ride.rideType ?? RideType.roadRide),
            color: theme.colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ride.title ?? 'Untitled Ride',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (widget.ride.rideType != null)
                  Text(
                    widget.ride.rideType!.titleName,
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
        if (widget.ride.desc?.isNotEmpty == true) ...[
          Text(
            'Description',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.ride.desc!,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.ride.snippet?.isNotEmpty == true) ...[
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
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              widget.ride.snippet!,
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
    if ((widget.ride.averageRating == null ||
            widget.ride.averageRating! <= 0) &&
        widget.ride.difficulty == null) {
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
          if (widget.ride.averageRating != null &&
              widget.ride.averageRating! > 0) ...[
            Row(
              children: [
                StarRating(
                  rating: widget.ride.averageRating!,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.ride.ratingDisplayText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (widget.ride.difficulty != null) const SizedBox(height: 8),
          ],

          // Difficulty display
          if (widget.ride.difficulty != null) ...[
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                DifficultyChip(
                  difficulty: widget.ride.difficulty!,
                  showDescription: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserRatingSection(BuildContext context, ThemeData theme) {
    final currentUser = FirebaseAuth.instance.currentUser;

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
                : _currentUserRating > 0
                    ? 'Your rating: $_currentUserRating star${_currentUserRating == 1 ? '' : 's'}'
                    : 'Tap to rate this ride',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Stars row
          Row(
            children: [
              ...List.generate(5, (index) {
                return GestureDetector(
                  onTap: currentUser != null
                      ? () => _handleUserRating(context, index + 1)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      _currentUserRating > index
                          ? Icons.star
                          : Icons.star_border,
                      color: currentUser == null
                          ? Colors.grey.withValues(alpha: 0.5)
                          : _currentUserRating > index
                              ? Colors.amber
                              : Colors.grey,
                      size: 32,
                    ),
                  ),
                );
              }),
            ],
          ),
          // Remove rating button on separate row to prevent overflow
          if (currentUser != null && _currentUserRating > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _handleUserRating(context, 0),
                child: Text(
                  'Remove Rating',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
          if (currentUser != null && _currentUserRating > 0) ...[
            const SizedBox(height: 4),
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

  Future<void> _handleUserRating(BuildContext context, int newRating) async {
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

    if (newRating == _currentUserRating) {
      // User tapped the same rating, do nothing
      return;
    }

    // Update UI immediately for better user experience
    setState(() {
      _currentUserRating = newRating;
    });

    try {
      final repository = RideRepository();

      if (newRating == 0) {
        await repository.removeUserRating(widget.rideId);
      } else {
        await repository.rateRide(widget.rideId, newRating);
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
      // Revert UI change on error
      setState(() {
        final originalRating = (widget.ride.userRatings?[currentUser.uid] ?? 0);
        _currentUserRating = originalRating;
      });

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

  Widget _buildVerificationSection(BuildContext context, ThemeData theme) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isUserVerified = currentUser != null &&
        (widget.ride.verifiedByUsers?.contains(currentUser.uid) ?? false);
    final verificationCount = widget.ride.verificationCount ?? 0;

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
                verificationCount >= 3 ? Icons.verified : Icons.warning,
                color: verificationCount >= 3 ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ride Verification',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: verificationCount >= 3 ? Colors.green : Colors.orange,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: verificationCount >= 3
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  verificationCount >= 3 ? 'VERIFIED' : 'UNVERIFIED',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: verificationCount >= 3 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            verificationCount >= 3
                ? 'This ride has been verified by $verificationCount users'
                : verificationCount > 0
                    ? 'This ride has $verificationCount verification${verificationCount == 1 ? '' : 's'} (needs 3 to be verified)'
                    : 'This ride has not been verified yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (currentUser != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _handleVerification(context),
                icon: Icon(isUserVerified ? Icons.verified : Icons.how_to_reg),
                label: Text(isUserVerified ? 'Remove Verification' : 'Verify This Ride'),
                style: FilledButton.styleFrom(
                  backgroundColor: isUserVerified
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  foregroundColor: isUserVerified
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Log in to verify this ride',
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

  Future<void> _handleVerification(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to verify rides'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final repository = RideRepository();
      final isCurrentlyVerified = widget.ride.verifiedByUsers?.contains(currentUser.uid) ?? false;

      if (isCurrentlyVerified) {
        await repository.removeVerification(widget.rideId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification removed'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await repository.verifyRide(widget.rideId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride verified successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update verification: $e'),
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
            widget.ride.dow?.titleName ?? 'Not specified',
            Icons.calendar_today,
          ),
          if (widget.ride.startTime != null)
            _buildInfoRow(
              context,
              'Start Time',
              TimeOfDay.fromDateTime(widget.ride.startTime!).format(context),
              Icons.access_time,
            ),
          if (widget.ride.rideDistance != null && widget.ride.rideDistance! > 0)
            _buildInfoRow(
              context,
              'Distance',
              '${widget.ride.rideDistance} miles',
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
          if (widget.ride.startPointDesc?.isNotEmpty == true)
            _buildInfoRow(
              context,
              'Starting Point',
              widget.ride.startPointDesc!,
              Icons.play_arrow,
            ),
          if (widget.ride.latlng != null) ...[
            _buildInfoRow(
              context,
              'Coordinates',
              '${widget.ride.latlng!.latitude.toStringAsFixed(6)}, ${widget.ride.latlng!.longitude.toStringAsFixed(6)}',
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
            widget.ride.contact!,
            Icons.person,
          ),
          if (widget.ride.phone?.isNotEmpty == true)
            _buildInfoRow(
              context,
              'Phone',
              widget.ride.phone!,
              Icons.phone,
            ),
        ],
      ),
    );
  }

  Widget _buildRouteUrlSection(BuildContext context, ThemeData theme) {
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
                Icons.link,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Route Link',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _launchRouteUrl(widget.ride.routeUrl!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('View Route'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.ride.routeUrl!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _launchRouteUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open link: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon) {
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
          if (widget.onEdit != null || widget.onDelete != null) ...[
            const SizedBox(width: 12),
            if (widget.onEdit != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onEdit?.call();
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (widget.onDelete != null) ...[
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(context, widget.onDelete!);
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
          content:
              Text('Are you sure you want to delete "${widget.ride.title}"?'),
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
