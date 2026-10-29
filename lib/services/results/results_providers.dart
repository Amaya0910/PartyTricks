import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/results/firebase_results_service.dart';
import 'package:party_tricks/services/results/results_service.dart';

final resultsServiceProvider = Provider<ResultsService>(
  (ref) => FirebaseResultsService(FirebaseFirestore.instance),
);
