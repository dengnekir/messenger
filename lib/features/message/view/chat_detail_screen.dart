import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../viewmodel/message_viewmodel.dart';
import '../model/message_model.dart';
import '../../core/colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? profilePicture;

  const ChatDetailScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.profilePicture,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageViewModel =
          Provider.of<MessageViewModel>(context, listen: false);
      messageViewModel.selectChat(widget.userId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageViewModel =
        Provider.of<MessageViewModel>(context, listen: false);

    messageViewModel.sendMessage(
      receiverId: widget.userId,
      text: _messageController.text,
    );
    _messageController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<MessageViewModel>(
        builder: (context, messageViewModel, child) {
          if (messageViewModel.state.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.accentColor),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: messageViewModel.state.messages.isEmpty
                    ? _buildEmptyChat()
                    : _buildMessageList(messageViewModel.state.messages),
              ),
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.cardColor.withOpacity(0.5),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.iconColor,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accentColor.withOpacity(0.2),
            radius: 18,
            backgroundImage: widget.profilePicture != null
                ? NetworkImage(widget.profilePicture!)
                : null,
            child: widget.profilePicture == null
                ? Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            CupertinoIcons.info,
            color: AppColors.iconColor,
          ),
          onPressed: () {
            // Profil detayları göster
          },
        ),
      ],
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 80,
            color: AppColors.accentColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sohbet henüz başlamadı',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk mesajı göndererek sohbeti başlat',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<MessageModel> messages) {
    final userId = currentUser?.uid;

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // En yeni mesajlar en altta
      padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMyMessage = message.senderId == userId;
        final showTime =
            index == 0 || _shouldShowTime(messages[index], messages[index - 1]);

        return Column(
          children: [
            if (showTime) _buildDateSeparator(message),
            _buildMessageBubble(message, isMyMessage),
          ],
        );
      },
    );
  }

  bool _shouldShowTime(MessageModel current, MessageModel previous) {
    final currentTime = current.timestamp.toDate();
    final previousTime = previous.timestamp.toDate();

    // Mesajlar arasında 5 dakikadan fazla zaman varsa veya farklı gönderenler varsa
    return currentTime.difference(previousTime).inMinutes > 5 ||
        current.senderId != previous.senderId;
  }

  Widget _buildDateSeparator(MessageModel message) {
    final DateTime messageDate = message.timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDay =
        DateTime(messageDate.year, messageDate.month, messageDate.day);

    String dateText;
    if (messageDay == today) {
      dateText = 'Bugün';
    } else if (messageDay == yesterday) {
      dateText = 'Dün';
    } else {
      dateText = DateFormat('d MMMM y', 'tr_TR').format(messageDate);
    }

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMyMessage) {
    final time = DateFormat.Hm().format(message.timestamp.toDate());

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMyMessage
              ? AppColors.accentColor.withOpacity(0.8)
              : AppColors.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMyMessage ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMyMessage ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.encryptedContent,
              style: TextStyle(
                color: isMyMessage ? Colors.white : AppColors.textColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMyMessage
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.secondaryTextColor,
                    ),
                  ),
                  if (isMyMessage) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor.withOpacity(0.8),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.iconColor,
              ),
              onPressed: () {
                // Medya ekleme özelliği eklenecek
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.inputColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: AppColors.textColor),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Mesaj yazın...',
                    hintStyle: TextStyle(color: AppColors.secondaryTextColor),
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.isNotEmpty;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color:
                    _isComposing ? AppColors.accentColor : AppColors.cardColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isComposing ? Icons.send : Icons.mic,
                  color: _isComposing ? Colors.white : AppColors.iconColor,
                ),
                onPressed: _isComposing ? _sendMessage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
