import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/user_service.dart';
import '../../core/services/api_client.dart';
import '../../core/models/user_model.dart';
import '../../routes/app_routes.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isSending = false;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _target = 'all';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await UserService.getUser();
    if (mounted) setState(() { _user = user; _isLoading = false; });
  }

  Future<void> _sendAnnouncement() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill title and message'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _isSending = true);
    try {
      final res = await ApiClient.post('/admin/announce', {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'target': _target,
      });
      if (mounted) {
        setState(() => _isSending = false);
        _titleController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Announcement sent to ${res['notified'] ?? 0} users!'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to send announcement. Try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showChangePasswordSheet(ThemeData theme) {
  final oldPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  bool isSubmitting = false;
  bool obscureOld = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLighter,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Change Password',
                        style: theme.textTheme.titleLarge),
                    Text('Enter your current password first',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.onSurfaceMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Old password
            TextFormField(
              controller: oldPasswordCtrl,
              obscureText: obscureOld,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    size: 20, color: AppTheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(obscureOld
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                      size: 20, color: AppTheme.onSurfaceMuted),
                  onPressed: () =>
                      setSheetState(() => obscureOld = !obscureOld),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // New password
            TextFormField(
              controller: newPasswordCtrl,
              obscureText: obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    size: 20, color: AppTheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                      size: 20, color: AppTheme.onSurfaceMuted),
                  onPressed: () =>
                      setSheetState(() => obscureNew = !obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Confirm password
            TextFormField(
              controller: confirmPasswordCtrl,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    size: 20, color: AppTheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                      size: 20, color: AppTheme.onSurfaceMuted),
                  onPressed: () => setSheetState(
                      () => obscureConfirm = !obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (oldPasswordCtrl.text.isEmpty ||
                            newPasswordCtrl.text.isEmpty ||
                            confirmPasswordCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                                backgroundColor: Colors.red,
                              ));
                          return;
                        }
                        if (newPasswordCtrl.text !=
                            confirmPasswordCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match'),
                                backgroundColor: Colors.red,
                              ));
                          return;
                        }
                        if (newPasswordCtrl.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Password must be at least 6 characters'),
                                backgroundColor: Colors.red,
                              ));
                          return;
                        }
                        setSheetState(() => isSubmitting = true);
                        try {
                          await ApiClient.put('/users/change-password', {
                            'old_password': oldPasswordCtrl.text,
                            'new_password': newPasswordCtrl.text,
                          });
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Password changed successfully!'),
                                  backgroundColor: AppTheme.success,
                                ));
                          }
                        } catch (e) {
                          setSheetState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Current password is incorrect.'),
                                  backgroundColor: Colors.red,
                                ));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: Theme.of(context).textTheme.titleMedium),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await UserService.clearUser();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.signUpLoginScreen,
                  (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              _buildHeader(theme),
              _buildProfileCard(theme),
              const SizedBox(height: 16),
              _buildAnnouncementCard(theme),
              const SizedBox(height: 16),
              _buildSection(theme, 'Admin Settings', [
                _menuItem(theme, Icons.security_rounded,
                    'Security Settings', 'Change password',
                    () => _showChangePasswordSheet(theme)),
                _menuItem(theme, Icons.help_outline_rounded,
                    'Help & Support', 'Get assistance', () {}),
                _menuItem(theme, Icons.info_outline_rounded,
                    'About VenueMate', 'Version 1.0.0', () {}),
              ]),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showSignOutDialog,
                    icon: const Icon(Icons.logout_rounded,
                        size: 18, color: AppTheme.error),
                    label: Text('Sign Out',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: AppTheme.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text('Admin Account', style: theme.textTheme.headlineMedium),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                size: 32, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_user?.name ?? 'Admin',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(_user?.email ?? '',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(204))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('Super Admin',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send Announcement',
                      style: theme.textTheme.titleMedium),
                  Text('Notify users on the platform',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Target selector
          Row(
            children: [
              Text('Send to:',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              _targetChip('All', 'all', theme),
              const SizedBox(width: 6),
              _targetChip('Customers', 'customers', theme),
              const SizedBox(width: 6),
              _targetChip('Owners', 'owners', theme),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Announcement Title',
              prefixIcon: Icon(Icons.title_rounded,
                  size: 18, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Write your announcement message...',
              prefixIcon: Icon(Icons.message_rounded,
                  size: 18, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendAnnouncement,
              icon: _isSending
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_isSending
                  ? 'Sending...'
                  : 'Send Announcement'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetChip(String label, String value, ThemeData theme) {
    final selected = _target == value;
    return GestureDetector(
      onTap: () => setState(() => _target = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.onSurfaceMuted)),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                  fontWeight: FontWeight.w600)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _menuItem(ThemeData theme, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppTheme.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}
