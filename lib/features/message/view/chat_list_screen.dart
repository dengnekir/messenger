import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../service/message_service.dart';
import '../../shared/utils/encryption_helper.dart';
import '../../core/colors.dart';
import 'chat_detail_screen.dart';
import '../../shared/model/user_model.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final MessageService _messageService = MessageService();
  List<DocumentSnapshot> _users = [];
  List<DocumentSnapshot> _filteredUsers = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();

    // Arama kontrolü
    _searchController.addListener(() {
      _filterUsers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _messageService.getAllApprovedUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Kullanıcılar yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final userData = user.data() as Map<String, dynamic>?;
        if (userData == null) return false;

        final firstName = userData['firstName']?.toString().toLowerCase() ?? '';
        final lastName = userData['lastName']?.toString().toLowerCase() ?? '';
        final email = userData['email']?.toString().toLowerCase() ?? '';

        return firstName.contains(lowercaseQuery) ||
            lastName.contains(lowercaseQuery) ||
            email.contains(lowercaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearching
            ? _buildSearchField()
            : const Text(
                'Sohbetler',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? CupertinoIcons.xmark : CupertinoIcons.search,
              color: AppColors.textColor,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentColor,
          labelColor: AppColors.accentColor,
          unselectedLabelColor: AppColors.secondaryTextColor,
          tabs: const [
            Tab(text: 'Sohbetler'),
            Tab(text: 'Kullanıcılar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Sohbetler sekmesi
          _buildChatsTab(),
          // Kullanıcılar sekmesi
          _buildUsersTab(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Kullanıcı ara...',
        hintStyle: TextStyle(color: AppColors.secondaryTextColor),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildChatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messageService.getChats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data?.docs ?? [];
        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.chat_bubble_2,
                  size: 70,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz sohbet yok',
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kullanıcılar sekmesinden birini seçerek\nsohbete başlayabilirsiniz',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            return _buildChatItem(chats[index]);
          },
        );
      },
    );
  }

  Widget _buildChatItem(DocumentSnapshot chat) {
    final chatData = chat.data() as Map<String, dynamic>;
    final participants = List<String>.from(chatData['participants'] ?? []);
    final currentUser =
        Provider.of<AuthViewModel>(context, listen: false).state.email;
    final lastMessage = chatData['lastMessage'] as String? ?? '';
    final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
    final unreadCount = chatData['unreadCount'] as int? ?? 0;

    // Diğer kullanıcı bilgisini bul
    final otherUserId = participants.firstWhere(
      (userId) => userId != currentUser,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();

        final firstName = userData['firstName'] ?? '';
        final lastName = userData['lastName'] ?? '';
        final profilePicture = userData['profilePicture'];

        // Şifreli son mesajı çözümleme
        return FutureBuilder<String>(
            future: EncryptionHelper.decryptMessage(lastMessage),
            builder: (context, decryptSnapshot) {
              final decryptedMessage =
                  decryptSnapshot.data ?? 'Mesaj yükleniyor...';

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        userId: otherUserId,
                        userName: '$firstName $lastName',
                        profilePicture: profilePicture,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: AppColors.accentColor.withOpacity(0.2),
                  backgroundImage: profilePicture != null
                      ? NetworkImage(profilePicture)
                      : null,
                  child: profilePicture == null
                      ? Text(
                          '${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ""}',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                title: Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  decryptedMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unreadCount > 0
                        ? AppColors.accentColor
                        : AppColors.secondaryTextColor,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Saat gösterimi
                    Text(
                      lastMessageTime != null
                          ? _formatMessageTime(lastMessageTime.toDate())
                          : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Okunmamış mesaj varsa bildirim
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            });
      },
    );
  }

  Widget _buildUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_2,
              size: 70,
              color: AppColors.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Aranan kullanıcı bulunamadı'
                  : 'Henüz onaylanmış kullanıcı yok',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final userData = user.data() as Map<String, dynamic>;
        final firstName = userData['firstName'] ?? '';
        final lastName = userData['lastName'] ?? '';
        final email = userData['email'] ?? '';
        final profilePicture = userData['profilePicture'];
        final lastSeen = userData['lastSeen'] != null
            ? (userData['lastSeen'] as Timestamp).toDate()
            : null;

        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  userId: user.id,
                  userName: '$firstName $lastName',
                  profilePicture: profilePicture,
                ),
              ),
            );
          },
          leading: CircleAvatar(
            backgroundColor: AppColors.accentColor.withOpacity(0.2),
            backgroundImage:
                profilePicture != null ? NetworkImage(profilePicture) : null,
            child: profilePicture == null
                ? Text(
                    '${firstName.isNotEmpty ? firstName[0] : ""}${lastName.isNotEmpty ? lastName[0] : ""}',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          title: Text(
            '$firstName $lastName',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            email,
            style: TextStyle(
              color: AppColors.secondaryTextColor,
            ),
          ),
          trailing: lastSeen != null
              ? Text(
                  'Son görülme: ${timeago.format(lastSeen, locale: 'tr')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryTextColor,
                  ),
                )
              : null,
        );
      },
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (today == messageDay) {
      // Bugün ise sadece saat:dakika
      return DateFormat.Hm().format(time);
    } else if (today.subtract(const Duration(days: 1)) == messageDay) {
      // Dün ise "Dün"
      return 'Dün';
    } else if (today.difference(messageDay).inDays < 7) {
      // Son 7 gün içinde ise gün adı
      return DateFormat.E('tr_TR').format(time);
    } else {
      // Daha eski ise tarih
      return DateFormat.yMd('tr_TR').format(time);
    }
  }
}
