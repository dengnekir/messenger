import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/admin_state.dart';
import '../viewmodel/admin_viewmodel.dart';
import '../../shared/model/user_model.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Admin durumunu ve kullanıcıları kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminViewModel =
          Provider.of<AdminViewModel>(context, listen: false);
      adminViewModel.checkAdminStatus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, adminViewModel, child) {
        // Admin değilse erişimi engelle
        if (!adminViewModel.state.isAdmin) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Yetkisiz Erişim'),
            ),
            body: const Center(
              child: Text(
                  'Bu sayfaya erişim yetkiniz bulunmamaktadır. Sadece admin kullanıcılar erişebilir.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Paneli'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Onay Bekleyenler'),
                Tab(text: 'Onaylı Kullanıcılar'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Onay bekleyen kullanıcılar listesi
              _buildUserList(
                adminViewModel.state.pendingUsers,
                adminViewModel.state.status,
                showApproveButton: true,
                onApprove: (uid) => adminViewModel.approveUser(uid),
                onReject: (uid) => adminViewModel.rejectUser(uid),
              ),

              // Onaylı kullanıcılar listesi
              _buildUserList(
                adminViewModel.state.approvedUsers,
                adminViewModel.state.status,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => adminViewModel.loadUsers(),
            tooltip: 'Yenile',
            child: const Icon(Icons.refresh),
          ),
        );
      },
    );
  }

  Widget _buildUserList(
    List<UserModel> users,
    AdminStatus status, {
    bool showApproveButton = false,
    Function(String)? onApprove,
    Function(String)? onReject,
  }) {
    if (status == AdminStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == AdminStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Provider.of<AdminViewModel>(context).state.errorMessage ??
                  'Bir hata oluştu',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  Provider.of<AdminViewModel>(context, listen: false)
                      .loadUsers(),
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return const Center(
        child: Text('Kullanıcı bulunamadı'),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: user.role == 'admin'
                  ? const Icon(Icons.admin_panel_settings)
                  : Text(user.firstName.isNotEmpty
                      ? user.firstName[0]
                      : (user.email.isNotEmpty ? user.email[0] : '?')),
            ),
            title: Text(user.fullName.isNotEmpty ? user.fullName : user.email),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Text('Kayıt: ${_formatDate(user.createdAt)}'),
                if (user.role != null)
                  Text(
                    'Rol: ${user.role == 'admin' ? 'Admin' : 'Kullanıcı'}',
                    style: TextStyle(
                      color: user.role == 'admin' ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: showApproveButton
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => onApprove?.call(user.uid),
                        tooltip: 'Onayla',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => onReject?.call(user.uid),
                        tooltip: 'Reddet',
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
