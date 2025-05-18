import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final Timestamp lastMessageTime;
  final String lastMessageSenderId;
  final bool hasUnreadMessages;
  final Map<String, dynamic> participantInfo;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.hasUnreadMessages,
    required this.participantInfo,
  });

  // Firestore'dan gelen veriler ile model oluşturma
  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatModel(
      id: docId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] ?? Timestamp.now(),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      hasUnreadMessages: map['hasUnreadMessages'] ?? false,
      participantInfo: Map<String, dynamic>.from(map['participantInfo'] ?? {}),
    );
  }

  // Model verilerini Firestore'a kaydetmek için dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastMessageSenderId': lastMessageSenderId,
      'hasUnreadMessages': hasUnreadMessages,
      'participantInfo': participantInfo,
    };
  }

  // Okunmadı durumunu güncellemek için kopya oluşturma
  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    Timestamp? lastMessageTime,
    String? lastMessageSenderId,
    bool? hasUnreadMessages,
    Map<String, dynamic>? participantInfo,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      participantInfo: participantInfo ?? this.participantInfo,
    );
  }

  // Diğer kullanıcının ID'sini getir
  String getOtherUserId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId,
        orElse: () => '');
  }

  // Diğer kullanıcının adını getir
  String getOtherUserName(String currentUserId) {
    final otherUserId = getOtherUserId(currentUserId);
    if (otherUserId.isEmpty || participantInfo[otherUserId] == null) {
      return 'Bilinmeyen Kullanıcı';
    }

    return '${participantInfo[otherUserId]['firstName'] ?? ''} ${participantInfo[otherUserId]['lastName'] ?? ''}';
  }

  // Diğer kullanıcının profil fotoğrafını getir
  String? getOtherUserPhotoUrl(String currentUserId) {
    final otherUserId = getOtherUserId(currentUserId);
    if (otherUserId.isEmpty || participantInfo[otherUserId] == null) {
      return null;
    }

    return participantInfo[otherUserId]['photoUrl'];
  }
}
