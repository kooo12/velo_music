import 'package:cloud_firestore/cloud_firestore.dart';

class PromotedApp {
  final String id;
  final String appName;
  final String packageName;
  final String? appStoreId;
  final String iconUrl;
  final String description;
  final String playStoreUrl;
  final String appStoreUrl;
  final int order;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PromotedApp({
    required this.id,
    required this.appName,
    required this.packageName,
    this.appStoreId,
    required this.iconUrl,
    required this.description,
    required this.playStoreUrl,
    required this.appStoreUrl,
    required this.order,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory PromotedApp.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromotedApp(
      id: doc.id,
      appName: data['appName'] ?? '',
      packageName: data['packageName'] ?? '',
      appStoreId: data['appStoreId'],
      iconUrl: data['iconUrl'] ?? '',
      description: data['description'] ?? '',
      playStoreUrl: data['playStoreUrl'] ?? '',
      appStoreUrl: data['appStoreUrl'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appName': appName,
      'packageName': packageName,
      'appStoreId': appStoreId,
      'iconUrl': iconUrl,
      'description': description,
      'playStoreUrl': playStoreUrl,
      'appStoreUrl': appStoreUrl,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PromotedApp copyWith({
    String? id,
    String? appName,
    String? packageName,
    String? appStoreId,
    String? iconUrl,
    String? description,
    String? playStoreUrl,
    String? appStoreUrl,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromotedApp(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      appStoreId: appStoreId ?? this.appStoreId,
      iconUrl: iconUrl ?? this.iconUrl,
      description: description ?? this.description,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      appStoreUrl: appStoreUrl ?? this.appStoreUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
