import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mymap/models/auto_complete_result.dart';
import 'package:mymap/providers/providers.dart';
import 'package:mymap/services/map_services.dart';

class MapSearchWidget extends ConsumerStatefulWidget {
  final Function(double lat, double lng) onLocationSelected;
  final VoidCallback onClose;
  final bool isVisible;

  const MapSearchWidget({
    Key? key,
    required this.onLocationSelected,
    required this.onClose,
    required this.isVisible,
  }) : super(key: key);

  @override
  ConsumerState<MapSearchWidget> createState() => _MapSearchWidgetState();
}

class _MapSearchWidgetState extends ConsumerState<MapSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  static const int _searchDebounceMs = 700;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    final allSearchResults = ref.read(placeResultsProvider.notifier);
    final searchFlag = ref.read(searchToggleProvider.notifier);

    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: _searchDebounceMs), () async {
      if (value.length > 2) {
        if (!ref.read(searchToggleProvider).searchToggle) {
          searchFlag.toggleSearch();
        }

        try {
          print('🔍 Searching for: "$value"');
          List<AutoCompleteResult> searchResults =
              await MapServices().searchPlaces(value);
          print('📝 Setting ${searchResults.length} results');
          allSearchResults.setResults(searchResults);
        } catch (e) {
          debugPrint('❌ Search error: $e');
          allSearchResults.setResults([]);
        }
      } else {
        allSearchResults.setResults([]);
      }
    });
  }

  void _handleClose() {
    final searchFlag = ref.read(searchToggleProvider.notifier);
    _searchController.clear();
    
    if (ref.read(searchToggleProvider).searchToggle) {
      searchFlag.toggleSearch();
    }
    
    widget.onClose();
  }

  Future<void> _handleLocationTap(AutoCompleteResult placeItem) async {
    try {
      final place = await MapServices().getPlace(placeItem.placeId);
      final lat = place['geometry']['location']['lat'] as double;
      final lng = place['geometry']['location']['lng'] as double;
      
      widget.onLocationSelected(lat, lng);
      
      final searchFlag = ref.read(searchToggleProvider.notifier);
      searchFlag.toggleSearch();
    } catch (e) {
      debugPrint('Error selecting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final allSearchResults = ref.watch(placeResultsProvider);
    final searchFlag = ref.watch(searchToggleProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Search field
          Positioned(
            top: 40.0,
            left: 15.0,
            right: 15.0,
            child: _buildSearchField(),
          ),
          // Search results
          if (searchFlag.searchToggle) _buildSearchResults(screenWidth),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 56.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.0),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0, 
            vertical: 16.0,
          ),
          border: InputBorder.none,
          hintText: 'Search locations...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _handleSearchChanged('');
                },
                icon: Icon(
                  Icons.clear,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Clear search',
              )
            : IconButton(
                onPressed: _handleClose,
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Close search',
              ),
        ),
        onChanged: (value) {
          setState(() {}); // Rebuild to update suffix icon
          _handleSearchChanged(value);
        },
      ),
    );
  }

  Widget _buildSearchResults(double screenWidth) {
    final allSearchResults = ref.watch(placeResultsProvider);

    return Positioned(
      top: 105.0, // Position below the search field (40 + 56 + 9 margin)
      left: 15.0,
      right: 15.0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: allSearchResults.allReturnedResults.isNotEmpty
              ? ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: allSearchResults.allReturnedResults.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                    indent: 52.0, // Align with text
                  ),
                  itemBuilder: (context, index) => _buildSearchResultItem(
                    allSearchResults.allReturnedResults[index]
                  ),
                )
              : _buildNoResultsView(),
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(AutoCompleteResult placeItem) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          _handleLocationTap(placeItem);
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _extractMainLocation(placeItem.description ?? ''),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_extractSecondaryLocation(placeItem.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        _extractSecondaryLocation(placeItem.description ?? ''),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Icon(
                Icons.arrow_outward,
                size: 16.0,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractMainLocation(String description) {
    // Extract the main location (usually the first part before the comma)
    final parts = description.split(',');
    return parts.first.trim();
  }

  String _extractSecondaryLocation(String description) {
    // Extract the secondary location info (everything after the first comma)
    final parts = description.split(',');
    if (parts.length > 1) {
      return parts.skip(1).join(',').trim();
    }
    return '';
  }

  Widget _buildNoResultsView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16.0),
          Text(
            'No locations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20.0),
          OutlinedButton.icon(
            onPressed: () {
              final searchFlag = ref.read(searchToggleProvider.notifier);
              searchFlag.toggleSearch();
            },
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Close Search'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}