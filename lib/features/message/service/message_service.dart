import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/message_model.dart';
import '../../shared/utils/encryption_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tüm onaylanmış kullanıcıları getir
  Future<List<DocumentSnapshot>> getAllApprovedUsers() async {
    try {
      // Sadece 'users' koleksiyonundaki kullanıcıları getirir
      // (onaylanmış kullanıcılar)
      final querySnapshot = await _firestore
          .collection('users')
          .limit(10) // Maksimum 10 kullanıcı
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('Kullanıcılar getirilirken hata: $e');
      return [];
    }
  }

  // İki kullanıcı arasındaki mesajlaşma ID'sini oluştur
  String _getChatId(String userId1, String userId2) {
    // Alfabetik sıralama yaparak tutarlı bir ID oluştur
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Mesaj gönderme
  Future<bool> sendMessage(String receiverId, String messageText) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final senderId = user.uid;
      final chatId = _getChatId(senderId, receiverId);

      // Mesajı şifrele
      final encryptedContent =
          await EncryptionHelper.encryptMessage(messageText);

      // Yeni mesaj oluştur
      final messageData = MessageModel(
        id: '', // Firestore tarafından oluşturulacak
        senderId: senderId,
        receiverId: receiverId,
        encryptedContent: encryptedContent,
        timestamp: Timestamp.now(),
      ).toMap();

      // Mesajı kaydet
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Son mesaj bilgisini güncelle
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': encryptedContent,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [senderId, receiverId],
        'unreadCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Mesaj gönderilirken hata: $e');
      return false;
    }
  }

  // Mesajları gerçek zamanlı dinleme
  Stream<QuerySnapshot> getMessages(String otherUserId) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    final chatId = _getChatId(user.uid, otherUserId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50) // Son 50 mesaj
        .snapshots();
  }

  // Şifreli mesajları çözme
  Future<List<MessageModel>> decryptMessages(
      List<DocumentSnapshot> messages) async {
    final decryptedMessages = <MessageModel>[];

    for (final doc in messages) {
      final message =
          MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      try {
        // Şifrelenmiş içeriği çöz
        final decryptedContent =
            await EncryptionHelper.decryptMessage(message.encryptedContent);

        // Yeni bir mesaj objesi oluştur, çözülmüş içerikle
        final decryptedMessage = MessageModel(
          id: message.id,
          senderId: message.senderId,
          receiverId: message.receiverId,
          encryptedContent: decryptedContent, // Çözülmüş içerik
          timestamp: message.timestamp,
          isRead: message.isRead,
          mediaUrl: message.mediaUrl,
          mediaType: message.mediaType,
        );

        decryptedMessages.add(decryptedMessage);
      } catch (e) {
        print('Mesaj çözülürken hata: $e');
        // Hata durumunda orijinal şifreli mesajı ekle
        decryptedMessages.add(message);
      }
    }

    return decryptedMessages;
  }

  // Sohbetleri getir (son konuşulan kişiler)
  Stream<QuerySnapshot> getChats() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Mesajları okundu olarak işaretle
  Future<void> markMessagesAsRead(String otherUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final chatId = _getChatId(user.uid, otherUserId);

    try {
      // Okunmamış mesajları al
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      // Her mesajı okundu olarak işaretle
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Okunmamış mesaj sayısını sıfırla
      if (unreadMessages.docs.isNotEmpty) {
        batch.update(
            _firestore.collection('chats').doc(chatId), {'unreadCount': 0});
      }

      await batch.commit();
    } catch (e) {
      print('Mesajlar okundu olarak işaretlenirken hata: $e');
    }
  }
}
