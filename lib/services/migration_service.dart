import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _ridesCollection = _firestore.collection('rides');

  /// Migrates existing ride documents to include separate latitude and longitude fields
  /// extracted from the GeoPoint latlng field
  static Future<MigrationResult> migrateGeoPointToLatLng({bool forceUpdate = false}) async {
    try {
      debugPrint('=== Starting GeoPoint to Lat/Lng Migration ===');

      // Get all ride documents
      final querySnapshot = await _ridesCollection.get();
      final totalDocs = querySnapshot.docs.length;

      debugPrint('Found $totalDocs documents to process');

      int processedCount = 0;
      int updatedCount = 0;
      int skippedCount = 0;
      List<String> errors = [];

      // Process documents in batches to avoid memory issues
      const batchSize = 50;
      final batches = <List<DocumentSnapshot>>[];

      for (int i = 0; i < querySnapshot.docs.length; i += batchSize) {
        final end = (i + batchSize < querySnapshot.docs.length)
            ? i + batchSize
            : querySnapshot.docs.length;
        batches.add(querySnapshot.docs.sublist(i, end));
      }

      debugPrint('Processing in ${batches.length} batches of up to $batchSize documents each');

      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = batches[batchIndex];
        final writeBatch = _firestore.batch();
        int batchUpdateCount = 0;

        debugPrint('Processing batch ${batchIndex + 1}/${batches.length}');

        for (final doc in batch) {
          try {
            processedCount++;
            final data = doc.data() as Map<String, dynamic>;

            // Check if latitude and longitude already exist (unless forced)
            if (!forceUpdate && data.containsKey('latitude') && data.containsKey('longitude')) {
              debugPrint('Document ${doc.id} already has lat/lng fields, skipping');
              skippedCount++;
              continue;
            }

            // Check if latlng GeoPoint exists
            final latlng = data['latlng'] as GeoPoint?;
            if (latlng == null) {
              debugPrint('Document ${doc.id} has no latlng field, skipping');
              skippedCount++;
              continue;
            }

            // Extract latitude and longitude from GeoPoint
            final latitude = latlng.latitude;
            final longitude = latlng.longitude;

            // Add the new fields to the batch update
            writeBatch.update(doc.reference, {
              'latitude': latitude,
              'longitude': longitude,
            });

            batchUpdateCount++;
            debugPrint('Queued update for ${doc.id}: lat=$latitude, lng=$longitude');

          } catch (e) {
            final error = 'Error processing document ${doc.id}: $e';
            debugPrint(error);
            errors.add(error);
          }
        }

        // Commit the batch if there are updates
        if (batchUpdateCount > 0) {
          debugPrint('About to commit batch ${batchIndex + 1} with $batchUpdateCount updates...');
          await writeBatch.commit();
          updatedCount += batchUpdateCount;
          debugPrint('✅ Batch ${batchIndex + 1} committed successfully: $batchUpdateCount updates');
        } else {
          debugPrint('Batch ${batchIndex + 1} had no updates to commit');
        }
      }

      final result = MigrationResult(
        totalDocuments: totalDocs,
        processedDocuments: processedCount,
        updatedDocuments: updatedCount,
        skippedDocuments: skippedCount,
        errors: errors,
      );

      debugPrint('=== Migration Complete ===');
      debugPrint('Total documents: $totalDocs');
      debugPrint('Processed: $processedCount');
      debugPrint('Updated: $updatedCount');
      debugPrint('Skipped: $skippedCount');
      debugPrint('Errors: ${errors.length}');

      return result;

    } catch (e) {
      debugPrint('Migration failed with error: $e');
      throw MigrationException('Migration failed: $e');
    }
  }

  /// Verifies that the migration was successful by checking a sample of documents
  static Future<bool> verifyMigration() async {
    try {
      debugPrint('=== Verifying Migration ===');

      final querySnapshot = await _ridesCollection.limit(10).get();

      int validCount = 0;
      int totalCount = querySnapshot.docs.length;

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final hasLatitude = data.containsKey('latitude') && data['latitude'] != null;
        final hasLongitude = data.containsKey('longitude') && data['longitude'] != null;
        final hasLatlng = data.containsKey('latlng') && data['latlng'] != null;

        if (hasLatitude && hasLongitude && hasLatlng) {
          final GeoPoint geoPoint = data['latlng'];
          final double latitude = data['latitude'].toDouble();
          final double longitude = data['longitude'].toDouble();

          // Verify that the values match
          if ((geoPoint.latitude - latitude).abs() < 0.000001 &&
              (geoPoint.longitude - longitude).abs() < 0.000001) {
            validCount++;
            debugPrint('Document ${doc.id} verified successfully');
          } else {
            debugPrint('Document ${doc.id} has mismatched values: '
                'GeoPoint(${geoPoint.latitude}, ${geoPoint.longitude}) vs '
                'Fields($latitude, $longitude)');
          }
        } else {
          debugPrint('Document ${doc.id} missing required fields: '
              'lat=$hasLatitude, lng=$hasLongitude, latlng=$hasLatlng');
        }
      }

      final success = validCount == totalCount;
      debugPrint('Verification result: $validCount/$totalCount documents valid ($success)');

      return success;

    } catch (e) {
      debugPrint('Verification failed: $e');
      return false;
    }
  }
}

class MigrationResult {
  final int totalDocuments;
  final int processedDocuments;
  final int updatedDocuments;
  final int skippedDocuments;
  final List<String> errors;

  MigrationResult({
    required this.totalDocuments,
    required this.processedDocuments,
    required this.updatedDocuments,
    required this.skippedDocuments,
    required this.errors,
  });

  bool get wasSuccessful => errors.isEmpty && updatedDocuments > 0;

  String get summary =>
      'Migration completed: $updatedDocuments updated, $skippedDocuments skipped, ${errors.length} errors';
}

class MigrationException implements Exception {
  final String message;
  MigrationException(this.message);

  @override
  String toString() => 'MigrationException: $message';
}