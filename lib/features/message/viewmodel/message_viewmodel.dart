import 'dart:async';
import 'package:flutter/material.dart';
import '../model/message_model.dart';
import '../model/chat_model.dart';
import '../model/message_state.dart';
import '../../shared/services/message_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageViewModel extends ChangeNotifier {
  final MessageService _messageService = MessageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MessageState _state = MessageState();
  MessageState get state => _state;

  StreamSubscription? _chatsSubscription;
  StreamSubscription? _messagesSubscription;

  MessageViewModel() {
    _init();
  }

  void _init() {
    _listenToChats();
  }

  // Kullanıcının sohbetlerini dinle
  void _listenToChats() {
    _chatsSubscription?.cancel();
    _chatsSubscription = _messageService.getUserChats().listen(
      (chats) {
        _state = _state.copyWith(
          chats: chats,
          status: MessageStatus.success,
          isLoading: false,
        );
        notifyListeners();
      },
      onError: (error) {
        _state = _state.copyWith(
          status: MessageStatus.error,
          errorMessage: 'Sohbetler yüklenemedi: $error',
          isLoading: false,
        );
        notifyListeners();
      },
    );
  }

  // Belirli bir sohbetteki mesajları dinle
  void selectChat(String chatId) {
    _messagesSubscription?.cancel();

    _state = _state.copyWith(
      selectedChatId: chatId,
      isLoading: true,
      status: MessageStatus.loading,
    );
    notifyListeners();

    _messagesSubscription = _messageService.getChatMessages(chatId).listen(
      (messages) {
        _state = _state.copyWith(
          messages: messages,
          status: MessageStatus.success,
          isLoading: false,
        );
        notifyListeners();

        // Sohbeti okundu olarak işaretle
        _messageService.markChatAsRead(chatId);
      },
      onError: (error) {
        _state = _state.copyWith(
          status: MessageStatus.error,
          errorMessage: 'Mesajlar yüklenemedi: $error',
          isLoading: false,
        );
        notifyListeners();
      },
    );
  }

  // Seçili sohbeti temizle
  void clearSelectedChat() {
    _messagesSubscription?.cancel();
    _state = _state.copyWith(
      selectedChatId: null,
      messages: [],
    );
    notifyListeners();
  }

  // Yeni mesaj gönder
  Future<void> sendMessage({
    required String receiverId,
    required String text,
    String? imageUrl,
  }) async {
    if (text.trim().isEmpty && imageUrl == null) return;

    _state = _state.copyWith(
      status: MessageStatus.sending,
      isSending: true,
    );
    notifyListeners();

    try {
      await _messageService.sendMessage(
        receiverId: receiverId,
        text: text.trim(),
        imageUrl: imageUrl,
      );

      _state = _state.copyWith(
        status: MessageStatus.sent,
        isSending: false,
        errorMessage: null,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: MessageStatus.failed,
        errorMessage: 'Mesaj gönderilemedi: $e',
        isSending: false,
      );
      notifyListeners();
    }
  }

  // Kullanıcı arama
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.length < 3) return [];

    try {
      return await _messageService.searchUsers(query);
    } catch (e) {
      _state = _state.copyWith(
        status: MessageStatus.error,
        errorMessage: 'Kullanıcı araması başarısız: $e',
      );
      notifyListeners();
      return [];
    }
  }

  // Sohbeti sil
  Future<void> deleteChat(String chatId) async {
    try {
      await _messageService.deleteChat(chatId);
      if (_state.selectedChatId == chatId) {
        clearSelectedChat();
      }
    } catch (e) {
      _state = _state.copyWith(
        status: MessageStatus.error,
        errorMessage: 'Sohbet silinemedi: $e',
      );
      notifyListeners();
    }
  }

  // Mesajı sil
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId);
    } catch (e) {
      _state = _state.copyWith(
        status: MessageStatus.error,
        errorMessage: 'Mesaj silinemedi: $e',
      );
      notifyListeners();
    }
  }

  // Kullanıcı ile yeni sohbet başlat veya var olan sohbeti aç
  Future<String> startChatWithUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    // İki kullanıcı arasındaki sohbet ID'sini oluştur
    final chatId = _messageService.getChatId(currentUserId, userId);

    // Bu sohbet mevcut mu kontrol et
    final existingChat = _state.chats.where((c) => c.id == chatId).toList();

    if (existingChat.isEmpty) {
      // Eğer sohbet yoksa, boş bir mesaj göndererek sohbet başlat
      await _messageService.sendMessage(
        receiverId: userId,
        text: 'Merhaba 👋', // İlk mesaj
      );
    }

    // Sohbet ID'sini döndür (ister yeni ister mevcut)
    return chatId;
  }

  // Temizlik işlemleri
  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
