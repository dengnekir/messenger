import 'chat_model.dart';
import 'message_model.dart';

enum MessageStatus { initial, loading, success, error, sending, sent, failed }

class MessageState {
  final MessageStatus status;
  final List<MessageModel> messages;
  final List<ChatModel> chats;
  final String? selectedChatId;
  final String? errorMessage;
  final bool isLoading;
  final bool isSending;

  MessageState({
    this.status = MessageStatus.initial,
    this.messages = const [],
    this.chats = const [],
    this.selectedChatId,
    this.errorMessage,
    this.isLoading = false,
    this.isSending = false,
  });

  // Durum güncelleme için kopya oluştur
  MessageState copyWith({
    MessageStatus? status,
    List<MessageModel>? messages,
    List<ChatModel>? chats,
    String? selectedChatId,
    String? errorMessage,
    bool? isLoading,
    bool? isSending,
  }) {
    return MessageState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      chats: chats ?? this.chats,
      selectedChatId: selectedChatId ?? this.selectedChatId,
      errorMessage: errorMessage, // null gelirse errorMessage'ı silmek için
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
    );
  }

  // Seçili sohbeti getir
  ChatModel? get selectedChat {
    if (selectedChatId == null) return null;
    try {
      return chats.firstWhere((chat) => chat.id == selectedChatId);
    } catch (_) {
      return null;
    }
  }

  // Okunmamış mesajları olan sohbetleri getir
  List<ChatModel> get unreadChats {
    return chats.where((chat) => chat.hasUnreadMessages).toList();
  }

  // Okunmamış mesaj sayısını getir
  int get unreadMessagesCount {
    return unreadChats.length;
  }
}
