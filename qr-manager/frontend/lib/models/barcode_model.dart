import 'dart:convert';

class BarcodeModel {
  final String? id;
  final String code;
  final String type;
  final DateTime timestamp;
  final bool isSyncing;
  final bool isSynced;

  BarcodeModel({
    this.id,
    required this.code,
    required this.type,
    required this.timestamp,
    this.isSyncing = false,
    this.isSynced = false,
  });

  BarcodeModel copyWith({
    String? id,
    String? code,
    String? type,
    DateTime? timestamp,
    bool? isSyncing,
    bool? isSynced,
  }) {
    return BarcodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isSyncing: isSyncing ?? this.isSyncing,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isSyncing': isSyncing,
      'isSynced': isSynced,
    };
  }

  factory BarcodeModel.fromJson(Map<String, dynamic> json) {
    return BarcodeModel(
      id: json['id'],
      code: json['code'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      isSyncing: json['isSyncing'] ?? false,
      isSynced: json['isSynced'] ?? false,
    );
  }

  String toJsonString() => json.encode(toJson());

  factory BarcodeModel.fromJsonString(String source) =>
      BarcodeModel.fromJson(json.decode(source));
}
