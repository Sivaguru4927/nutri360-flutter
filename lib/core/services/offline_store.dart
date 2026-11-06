// =============================================================================
// FILE: offline_store.dart
// PURPOSE: Implements a local-first offline storage layer for the Nutri360 app
//          using Hive as the embedded key-value database. Stores raw JSON maps
//          without requiring any build_runner generated adapters.
// =============================================================================

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/child.dart';
import '../models/growth_record.dart';
import '../models/nutrition_record.dart';
import 'database_service.dart';

class OfflineStore {
  static final OfflineStore _instance = OfflineStore._internal();
  factory OfflineStore() => _instance;
  static OfflineStore get instance => _instance;

  OfflineStore._internal();

  late Box<dynamic> _childrenBox;
  late Box<dynamic> _growthQueueBox;
  late Box<dynamic> _nutritionQueueBox;

  final DatabaseService _db = DatabaseService.instance;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isFlushing = false;

  Future<void> init() async {
    _childrenBox = await Hive.openBox<dynamic>('children');
    _growthQueueBox = await Hive.openBox<dynamic>('growth_queue');
    _nutritionQueueBox = await Hive.openBox<dynamic>('nutrition_queue');

    _startConnectivityWatcher();
  }

  void _startConnectivityWatcher() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && !_isFlushing) {
        _flushQueues();
      }
    });
  }

  Future<void> _flushQueues() async {
    _isFlushing = true;
    try {
      await _flushGrowthQueue();
      await _flushNutritionQueue();
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> _flushGrowthQueue() async {
    final keys = _growthQueueBox.keys.toList();
    for (final key in keys) {
      final raw = _growthQueueBox.get(key);
      if (raw == null) continue;

      try {
        final record = GrowthRecord.fromJson(Map<String, dynamic>.from(raw as Map));
        await _db.saveGrowthRecord(record);
        await _growthQueueBox.delete(key);
      } catch (e) {
        // ignore: avoid_print
        print('[OfflineStore] Growth record sync error: $e');
      }
    }
  }

  Future<void> _flushNutritionQueue() async {
    final keys = _nutritionQueueBox.keys.toList();
    for (final key in keys) {
      final raw = _nutritionQueueBox.get(key);
      if (raw == null) continue;
      // When Supabase endpoint is ready, flush here
      await _nutritionQueueBox.delete(key);
    }
  }

  Future<void> cacheChildren(List<Child> children) async {
    final list = children.map((c) => c.toJson()).toList();
    await _childrenBox.put(0, list);
  }

  Future<List<Child>> getCachedChildren() async {
    final raw = _childrenBox.get(0);
    if (raw == null) return [];
    try {
      return (raw as List<dynamic>)
          .map((item) => Child.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> queueGrowthRecord(GrowthRecord record) async {
    await _growthQueueBox.add(record.toJson());
  }

  Future<void> queueNutritionRecord(NutritionScreeningRecord record) async {
    await _nutritionQueueBox.add(record.toJson());
  }

  int get pendingSyncCount =>
      _growthQueueBox.length + _nutritionQueueBox.length;

  Future<bool> manualSync() async {
    if (_isFlushing) return false;
    final countBefore = pendingSyncCount;
    await _flushQueues();
    return pendingSyncCount == 0 || pendingSyncCount < countBefore;
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _childrenBox.close();
    await _growthQueueBox.close();
    await _nutritionQueueBox.close();
  }
}
