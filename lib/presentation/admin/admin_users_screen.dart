import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/api_client.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/admin/users');
      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(res['users'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _suspendUser(String id, bool suspend) async {
    try {
      await ApiClient.put('/admin/users/$id/suspend?suspend=$suspend', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(suspend
              ? 'User account suspended.'
              : 'User account reactivated.'),
          backgroundColor:
              suspend ? AppTheme.error : AppTheme.success,
        ));
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Action failed. Try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  List<Map<String, dynamic>> _filtered(String role) {
    var list = role == 'all'
        ? _allUsers
        : _allUsers.where((u) => u['userRole'] == role).toList();
    if (_searchQuery.isNotEmpty) {
      list = list.where((u) =>
          (u['name'] ?? '').toString().toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (u['email'] ?? '').toString().toLowerCase()
              .contains(_searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            _buildSearchBar(theme),
            _buildTabBar(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUserList(theme, 'all'),
                  _buildUserList(theme, 'customer'),
                  _buildUserList(theme, 'owner'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Management', style: theme.textTheme.headlineMedium),
          Text('Manage customers and owners',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceMuted)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          hintText: 'Search users by name or email...',
          prefixIcon: Icon(Icons.search_rounded,
              color: AppTheme.onSurfaceMuted, size: 20),
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    final customers = _allUsers
        .where((u) => u['userRole'] == 'customer').length;
    final owners = _allUsers
        .where((u) => u['userRole'] == 'owner').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.onSurfaceMuted,
        labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: 'All (${_allUsers.length})'),
          Tab(text: 'Customers ($customers)'),
          Tab(text: 'Owners ($owners)'),
        ],
      ),
    );
  }

  Widget _buildUserList(ThemeData theme, String role) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final users = _filtered(role);
    if (users.isEmpty) {
      return Center(
        child: Text('No users found',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.onSurfaceMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildUserCard(theme, users[i]),
      ),
    );
  }

  Widget _buildUserCard(ThemeData theme, Map<String, dynamic> user) {
    final isActive = user['is_active'] != false;
    final isOwner = user['userRole'] == 'owner';
    final name = user['name'] ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isActive
            ? null
            : Border.all(color: AppTheme.error.withAlpha(77)),
        boxShadow: [BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: isOwner
                  ? AppTheme.primaryLighter
                  : AppTheme.infoContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty
                    ? name.substring(0, 1).toUpperCase()
                    : 'U',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: isOwner ? AppTheme.primary : AppTheme.info,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? AppTheme.primaryLighter
                            : AppTheme.infoContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOwner ? 'Owner' : 'Customer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: isOwner
                              ? AppTheme.primary
                              : AppTheme.info,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(user['email'] ?? '',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted),
                    overflow: TextOverflow.ellipsis),
                if (!isActive)
                  Text('SUSPENDED',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppTheme.error)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showUserOptions(theme, user),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_vert_rounded,
                  size: 18, color: AppTheme.onSurfaceMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserOptions(ThemeData theme, Map<String, dynamic> user) {
    final isActive = user['is_active'] != false;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['name'] ?? '', style: theme.textTheme.titleMedium),
            Text(user['email'] ?? '',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceMuted)),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isActive
                    ? Icons.block_rounded
                    : Icons.check_circle_rounded,
                color: isActive ? AppTheme.error : AppTheme.success,
              ),
              title: Text(
                isActive ? 'Suspend Account' : 'Reactivate Account',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isActive ? AppTheme.error : AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _suspendUser(user['id'], isActive);
              },
            ),
          ],
        ),
      ),
    );
  }
}
