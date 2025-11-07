import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final Timestamp createdAt;

  UserData({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
  });

  // (Firestore DocumentSnapshot용)
  factory UserData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'New User',
      role: data['role'] ?? 'user',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}