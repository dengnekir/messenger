import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../viewmodel/message_viewmodel.dart';
import 'chat_detail_screen.dart';
import '../../core/colors.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({Key? key}) : super(key: key);

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _showInitialHint = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _showInitialHint = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showInitialHint = false;
    });

    final messageViewModel =
        Provider.of<MessageViewModel>(context, listen: false);
    final results = await messageViewModel.searchUsers(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Kullanıcı Ara',
          style: TextStyle(color: AppColors.textColor),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.iconColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.accentColor),
                    ),
                  )
                : _showInitialHint
                    ? _buildInitialHint()
                    : _searchResults.isEmpty
                        ? _buildNoResults()
                        : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inputColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: AppColors.inputBorderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => _searchUsers(value),
          style: TextStyle(color: AppColors.textColor),
          decoration: InputDecoration(
            hintText: 'Ad veya soyada göre ara',
            hintStyle: TextStyle(color: AppColors.inputHintColor),
            prefixIcon: Icon(
              CupertinoIcons.search,
              color: AppColors.accentColor,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.secondaryTextColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchResults = [];
                        _showInitialHint = true;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_2,
            size: 80,
            color: AppColors.accentColor.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Kullanıcı Ara',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sohbet başlatmak için kullanıcı\naramak için en az 3 harf girin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 80,
            color: AppColors.accentColor.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Sonuç Bulunamadı',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_searchController.text} için sonuç bulunamadı.\nBaşka bir arama yapmayı deneyin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final String fullName = '${user['firstName']} ${user['lastName']}';
        final String email = user['email'] ?? '';
        final String? photoUrl = user['photoUrl'];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: AppColors.accentColor.withOpacity(0.2),
              radius: 25,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            title: Text(
              fullName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            subtitle: Text(
              email,
              style: TextStyle(
                color: AppColors.secondaryTextColor,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.chat_bubble_outline,
                color: AppColors.accentColor,
              ),
              onPressed: () => _startChat(user['id']),
            ),
            onTap: () => _startChat(user['id']),
          ),
        );
      },
    );
  }

  void _startChat(String userId) async {
    final messageViewModel =
        Provider.of<MessageViewModel>(context, listen: false);

    try {
      // Gösterge
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentColor),
          ),
        ),
      );

      // Sohbet başlat (veya mevcut sohbeti bul)
      final chatId = await messageViewModel.startChatWithUser(userId);

      // Göstergeyi kapat
      Navigator.pop(context);

      // Sohbet ekranına yönlendir
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(chatId: chatId),
          ),
        );
      }
    } catch (e) {
      // Göstergeyi kapat
      Navigator.pop(context);

      // Hata göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Bir hata oluştu: $e'),
        ),
      );
    }
  }
}
