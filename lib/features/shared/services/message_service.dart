import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../message/model/message_model.dart';
import '../../message/model/chat_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Koleksiyon referansları
  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Mevcut kullanıcı kimliğini al
  String? get _currentUserId => _auth.currentUser?.uid;

  // Tüm sohbetleri getir
  Stream<List<ChatModel>> getUserChats() {
    if (_currentUserId == null) return Stream.value([]);

    return _chatsCollection
        .where('participants', arrayContains: _currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ChatModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Belirli bir sohbetteki tüm mesajları getir
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _messagesCollection
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Yeni mesaj gönder
  Future<void> sendMessage({
    required String receiverId,
    required String text,
    String? imageUrl,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('Kullanıcı oturum açmış değil');
      }

      // Kullanıcı bilgilerini al
      final senderDoc = await _usersCollection.doc(_currentUserId).get();
      final receiverDoc = await _usersCollection.doc(receiverId).get();

      if (!senderDoc.exists || !receiverDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final senderData = senderDoc.data() as Map<String, dynamic>;
      final receiverData = receiverDoc.data() as Map<String, dynamic>;

      final senderName = '${senderData['firstName']} ${senderData['lastName']}';

      // Sohbet ID'si oluştur (her iki kullanıcı için de aynı olması için sıralama)
      final List<String> participantIds = [_currentUserId!, receiverId];
      participantIds.sort();
      final chatId = participantIds.join('_');

      // Mesaj verisi oluştur
      final messageData = MessageModel(
        id: '', // Firestore tarafından otomatik oluşturulacak
        senderId: _currentUserId!,
        receiverId: receiverId,
        encryptedContent: text, // Metin şifrelenmemiş
        timestamp: Timestamp.now(),
        isRead: false,
        mediaUrl: imageUrl,
      );

      // Katılımcı bilgilerini oluştur
      final Map<String, dynamic> participantInfo = {
        _currentUserId!: {
          'firstName': senderData['firstName'],
          'lastName': senderData['lastName'],
          'photoUrl': senderData['photoUrl'],
        },
        receiverId: {
          'firstName': receiverData['firstName'],
          'lastName': receiverData['lastName'],
          'photoUrl': receiverData['photoUrl'],
        },
      };

      // Önce sohbet dokümanının var olup olmadığını kontrol et
      final chatDoc = await _chatsCollection.doc(chatId).get();

      // Mesaj dokümanını oluştur ve ID'yi al
      final messageRef = await _messagesCollection
          .add(messageData.toMap()..addAll({'chatId': chatId}));

      // Sohbet dokümanını oluştur veya güncelle
      await _chatsCollection.doc(chatId).set({
        'participants': participantIds,
        'lastMessage': text,
        'lastMessageTime': Timestamp.now(),
        'lastMessageSenderId': _currentUserId,
        'hasUnreadMessages': true,
        'participantInfo': participantInfo,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': chatDoc.exists
            ? chatDoc.get('createdAt')
            : FieldValue.serverTimestamp(),
      });

      return;
    } catch (e) {
      throw Exception('Mesaj gönderilemedi: $e');
    }
  }

  // Mesajı okundu olarak işaretle
  Future<void> markMessageAsRead(String messageId) async {
    if (_currentUserId == null) return;

    try {
      final messageDoc = await _messagesCollection.doc(messageId).get();
      if (!messageDoc.exists) return;

      await _messagesCollection.doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Mesaj okundu olarak işaretlenemedi: $e');
    }
  }

  // Sohbeti okundu olarak işaretle
  Future<void> markChatAsRead(String chatId) async {
    if (_currentUserId == null) return;

    try {
      // Tüm okunmamış mesajları bul
      final unreadMessages = await _messagesCollection
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      // Batch işlemi ile tüm mesajları okundu olarak işaretle
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
        });
      }

      // Sohbeti okundu olarak işaretle
      batch.update(_chatsCollection.doc(chatId), {
        'hasUnreadMessages': false,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Sohbet okundu olarak işaretlenemedi: $e');
    }
  }

  // Sohbeti sil
  Future<void> deleteChat(String chatId) async {
    try {
      // Önce tüm mesajları sil
      final messages =
          await _messagesCollection.where('chatId', isEqualTo: chatId).get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Sonra sohbeti sil
      batch.delete(_chatsCollection.doc(chatId));

      await batch.commit();
    } catch (e) {
      throw Exception('Sohbet silinemedi: $e');
    }
  }

  // Belirli bir mesajı sil
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messagesCollection.doc(messageId).delete();
    } catch (e) {
      throw Exception('Mesaj silinemedi: $e');
    }
  }

  // İki kullanıcı arasındaki sohbet ID'sini getir
  String getChatId(String userId1, String userId2) {
    final List<String> participantIds = [userId1, userId2];
    participantIds.sort();
    return participantIds.join('_');
  }

  // Kullanıcı arama
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (_currentUserId == null || query.length < 3) return [];

    try {
      // Ad ve soyad alanlarında arama
      final firstNameResults = await _usersCollection
          .where('firstName', isGreaterThanOrEqualTo: query)
          .where('firstName', isLessThan: query + 'z')
          .get();

      final lastNameResults = await _usersCollection
          .where('lastName', isGreaterThanOrEqualTo: query)
          .where('lastName', isLessThan: query + 'z')
          .get();

      // Sonuçları birleştir ve kendini hariç tut
      final Set<String> userIds = {};
      final List<Map<String, dynamic>> results = [];

      for (var doc in firstNameResults.docs) {
        final userId = doc.id;
        if (userId != _currentUserId && !userIds.contains(userId)) {
          userIds.add(userId);
          results.add({
            'id': userId,
            'firstName': doc['firstName'],
            'lastName': doc['lastName'],
            'photoUrl': doc['photoUrl'],
            'email': doc['email'],
          });
        }
      }

      for (var doc in lastNameResults.docs) {
        final userId = doc.id;
        if (userId != _currentUserId && !userIds.contains(userId)) {
          userIds.add(userId);
          results.add({
            'id': userId,
            'firstName': doc['firstName'],
            'lastName': doc['lastName'],
            'photoUrl': doc['photoUrl'],
            'email': doc['email'],
          });
        }
      }

      return results;
    } catch (e) {
      throw Exception('Kullanıcı araması başarısız: $e');
    }
  }
}
