import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mymap/models/ride_data.dart';
import 'package:mymap/providers/ride_provider.dart';

/// Star rating widget for displaying and setting ride ratings
class StarRating extends ConsumerWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final Color unratedColor;
  final bool allowHalfRating;
  final bool interactive;
  final String? rideId;
  final VoidCallback? onRatingChanged;

  const StarRating({
    super.key,
    this.rating = 0.0,
    this.starCount = 5,
    this.size = 24.0,
    this.color = Colors.amber,
    this.unratedColor = Colors.grey,
    this.allowHalfRating = true,
    this.interactive = false,
    this.rideId,
    this.onRatingChanged,
  });

  Widget buildStar(BuildContext context, int index) {
    Icon icon;
    if (index >= rating) {
      icon = Icon(
        Icons.star_border,
        color: unratedColor,
        size: size,
      );
    } else if (index > rating - (allowHalfRating ? 0.5 : 1.0) && index < rating) {
      icon = Icon(
        Icons.star_half,
        color: color,
        size: size,
      );
    } else {
      icon = Icon(
        Icons.star,
        color: color,
        size: size,
      );
    }

    if (interactive && rideId != null) {
      return GestureDetector(
        onTap: () => _onStarTapped(context, index),
        child: icon,
      );
    }
    return icon;
  }

  void _onStarTapped(BuildContext context, int index) async {
    if (rideId == null) return;

    final provider = ProviderScope.containerOf(context);
    try {
      await provider.read(ridesProvider.notifier).rateRide(rideId!, index + 1);
      onRatingChanged?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rate ride: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) => buildStar(context, index)),
    );
  }
}

/// Widget to display ride verification status and allow users to verify
class VerificationBadge extends ConsumerWidget {
  final Ride ride;
  final String rideId;

  const VerificationBadge({
    super.key,
    required this.ride,
    required this.rideId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final verificationCount = ride.verificationCount ?? 0;
    // TODO: Get current user ID from Firebase Auth provider
    final currentUser = 'current_user_id';
    final isVerifiedByUser = ride.isVerifiedByUser(currentUser);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: verificationCount > 0
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: verificationCount > 0
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verificationCount > 0 ? Icons.verified : Icons.shield_outlined,
            size: 16,
            color: verificationCount > 0
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            ride.verificationDisplayText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: verificationCount > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toggleVerification(context, ref, isVerifiedByUser),
            child: Icon(
              isVerifiedByUser ? Icons.check_circle : Icons.add_circle_outline,
              size: 20,
              color: isVerifiedByUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleVerification(BuildContext context, WidgetRef ref, bool isVerified) async {
    try {
      if (isVerified) {
        await ref.read(ridesProvider.notifier).removeVerification(rideId);
      } else {
        await ref.read(ridesProvider.notifier).verifyRide(rideId);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update verification: $e')),
        );
      }
    }
  }
}

/// Widget to display ride difficulty level
class DifficultyChip extends StatelessWidget {
  final RideDifficulty difficulty;
  final bool showDescription;

  const DifficultyChip({
    super.key,
    required this.difficulty,
    this.showDescription = false,
  });

  Color _getDifficultyColor(BuildContext context) {
    switch (difficulty) {
      case RideDifficulty.easy:
        return Colors.green;
      case RideDifficulty.moderate:
        return Colors.orange;
      case RideDifficulty.difficult:
        return Colors.red;
      case RideDifficulty.expert:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getDifficultyColor(context);

    return Tooltip(
      message: showDescription ? difficulty.description : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          difficulty.titleName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Widget to display and open external route links
class ExternalRouteLinks extends StatelessWidget {
  final Ride ride;

  const ExternalRouteLinks({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    if (!ride.hasExternalRoute) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route Link',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildRouteButton(
          context,
          'View Route',
          Icons.route,
          ride.routeUrl!,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildRouteButton(
    BuildContext context,
    String label,
    IconData icon,
    String url,
    Color color,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _launchURL(context, url),
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }
}

/// Combined widget showing all ride quality indicators
class RideQualityIndicators extends StatelessWidget {
  final Ride ride;
  final String rideId;
  final bool compact;

  const RideQualityIndicators({
    super.key,
    required this.ride,
    required this.rideId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: [
          if (ride.averageRating != null && ride.averageRating! > 0)
            StarRating(rating: ride.averageRating!, size: 16),
          if (ride.averageRating != null && ride.averageRating! > 0)
            const SizedBox(width: 8),
          VerificationBadge(ride: ride, rideId: rideId),
          if (ride.difficulty != null) ...[
            const SizedBox(width: 8),
            DifficultyChip(difficulty: ride.difficulty!),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating row
        if (ride.averageRating != null && ride.averageRating! > 0)
          Row(
            children: [
              StarRating(
                rating: ride.averageRating!,
                interactive: true,
                rideId: rideId,
              ),
              const SizedBox(width: 8),
              Text(ride.ratingDisplayText),
            ],
          ),
        const SizedBox(height: 8),

        // Verification and difficulty row
        Row(
          children: [
            VerificationBadge(ride: ride, rideId: rideId),
            if (ride.difficulty != null) ...[
              const SizedBox(width: 12),
              DifficultyChip(difficulty: ride.difficulty!, showDescription: true),
            ],
          ],
        ),

        // External routes
        if (ride.hasExternalRoute) ...[
          const SizedBox(height: 12),
          ExternalRouteLinks(ride: ride),
        ],
      ],
    );
  }
}