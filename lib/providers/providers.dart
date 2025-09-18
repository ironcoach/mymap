import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mymap/models/auto_complete_result.dart';

final placeResultsProvider = NotifierProvider<PlaceResultsNotifier, PlaceResults>(PlaceResultsNotifier.new);

final searchToggleProvider = NotifierProvider<SearchToggleNotifier, SearchToggle>(SearchToggleNotifier.new);

class PlaceResults {
  List<AutoCompleteResult> allReturnedResults = [];
}

class PlaceResultsNotifier extends Notifier<PlaceResults> {
  @override
  PlaceResults build() {
    return PlaceResults();
  }

  void setResults(List<AutoCompleteResult> allPlaces) {
    state = PlaceResults()..allReturnedResults = allPlaces;
  }
}

class SearchToggle {
  bool searchToggle = false;
}

class SearchToggleNotifier extends Notifier<SearchToggle> {
  @override
  SearchToggle build() {
    return SearchToggle();
  }

  void toggleSearch() {
    state = SearchToggle()..searchToggle = !state.searchToggle;
  }
}
