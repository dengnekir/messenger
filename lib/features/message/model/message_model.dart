import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String encryptedContent; // Şifrelenmiş mesaj içeriği
  final Timestamp timestamp;
  final bool isRead;
  final String? mediaUrl; // Medya dosyaları için (resim, ses, vb.)
  final String? mediaType;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.encryptedContent,
    required this.timestamp,
    this.isRead = false,
    this.mediaUrl,
    this.mediaType,
  });

  // Firestore'dan Message oluşturma
  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      encryptedContent: map['encryptedContent'] ?? '',
      timestamp: (map['timestamp'] as Timestamp),
      isRead: map['isRead'] ?? false,
      mediaUrl: map['mediaUrl'],
      mediaType: map['mediaType'],
    );
  }

  // Firestore'a kaydetmek için map oluşturma
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'encryptedContent': encryptedContent,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    };
  }

  // Okundu olarak işaretleme
  MessageModel copyWithRead() {
    return MessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      encryptedContent: encryptedContent,
      timestamp: timestamp,
      isRead: true,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
    );
  }
}
