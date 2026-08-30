import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/user_model.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'package:dio/dio.dart';
import '../../core/services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_image_widget.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:venuemate/presentation/owner/owner_reviews_screen.dart';

class OwnerAccountScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  const OwnerAccountScreen({super.key, this.onNavigateToTab});

  @override
  State<OwnerAccountScreen> createState() => _OwnerAccountScreenState();
}

class _OwnerAccountScreenState extends State<OwnerAccountScreen> {
  bool _notificationsEnabled = true;
  UserModel? _user;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'venues': '0',
    'bookings': '0',
    'revenue': '0',
    'rating': '0.0',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await UserService.getUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
    try {
      final res = await ApiClient.get('/dashboard/owner/stats');
      if (mounted) {
        setState(() {
          _stats = {
            'venues': '${res['total_venues'] ?? 0}',
            'bookings': '${res['total_bookings'] ?? 0}',
            'revenue': _formatRevenue(res['total_revenue']),
            'rating': '${res['avg_rating'] ?? '0.0'}',
          };
        });
      }
    } catch (_) {}
  }

  String _formatRevenue(dynamic revenue) {
    if (revenue == null) return '0';
    final r = revenue is int ? revenue : (revenue as num).toInt();
    if (r >= 1000000) return '${(r / 1000000).toStringAsFixed(1)}M';
    if (r >= 1000) return '${(r / 1000).toStringAsFixed(0)}K';
    return r.toString();
  }

  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    try {
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      final res = await ApiClient.post('/venues/upload-image-base64', {
        'image': base64Image,
        'folder': 'profiles',
      });
      final photoUrl = res['url'];
      await ApiClient.put('/users/me', {'profile_photo': photoUrl});
      final updatedUser = _user!.copyWith(profileImageUrl: photoUrl);
      await UserService.saveUser(updatedUser,
          token: await UserService.getAuthToken() ?? '');
      if (mounted) {
        setState(() => _user = updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile photo updated!'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to upload photo. Try again.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditProfileSheet(ThemeData theme) {
    final nameCtrl = TextEditingController(text: _user?.name ?? '');
    final phoneCtrl = TextEditingController(text: _user?.phone ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Edit Profile', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Name cannot be empty'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            setSheetState(() => isSubmitting = true);
                            try {
                              await ApiClient.put('/users/me', {
                                'name': nameCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim().isEmpty
                                    ? null
                                    : phoneCtrl.text.trim(),
                              });

                              final updatedUser = _user!.copyWith(
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim().isEmpty
                                    ? _user?.phone
                                    : phoneCtrl.text.trim(),
                              );
                              await UserService.saveUser(
                                updatedUser,
                                token: await UserService.getAuthToken() ?? '',
                              );

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                setState(() => _user = updatedUser);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Profile updated successfully!'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              }
                            } on DioException catch (e) {
                              setSheetState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.response?.data?['detail'] ??
                                        'Update failed'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Update failed. Try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpSupportSheet(ThemeData theme) {
    final faqs = [
      {
        'q': 'How do I add a new venue?',
        'a': 'Go to Venues tab and tap "Add Venue". Fill in details, upload photos, and submit for admin verification.'
      },
      {
        'q': 'How long does venue verification take?',
        'a': 'Admin typically reviews and approves new venues within 24 hours.'
      },
      {
        'q': 'How do I respond to a bid?',
        'a': 'Go to Requests tab, open the Incoming tab, and tap "Send Quote" on any bid to submit your offer.'
      },
      {
        'q': 'How do I block unavailable dates?',
        'a': 'Open a venue and tap "Availability" to mark dates as unavailable on the calendar.'
      },
      {
        'q': 'How do I manage multiple venues?',
        'a': 'Each venue has its own Edit and Availability options. When quoting a bid, you can select which of your venues to offer.'
      },
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Help & Support', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  itemCount: faqs.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (_, i) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faqs[i]['q']!,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(faqs[i]['a']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.onSurfaceMuted, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_city_rounded,
                  color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Text('VenueMate', style: theme.textTheme.titleMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'AI-Powered Venue Booking & Recommendation System for Gujranwala.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceMuted),
            ),
            const SizedBox(height: 8),
            Text(
              'All Rights Reserved © 2026 VenueMate. Developed by Team VenueMate.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
              _buildVenueStatsRow(theme),
              const SizedBox(height: 16),
              _buildSection(theme, 'Venue Management', [
                _menuItem(
                  theme,
                  Icons.location_city_rounded,
                  'My Venues',
                  'Manage your listings',
                  AppTheme.primary,
                  () => widget.onNavigateToTab?.call(1),
                ),
                _menuItem(
                  theme,
                  Icons.request_quote_rounded,
                  'Manage Requests',
                  'Bids & quotations',
                  AppTheme.warning,
                  () => widget.onNavigateToTab?.call(3),
                ),
                _menuItem(
                  theme,
                  Icons.star_rounded,
                  'My Reviews',
                  '${_stats['rating']} avg rating',
                  AppTheme.gold,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OwnerReviewsScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _buildSection(theme, 'Business Settings', [
                _switchItem(
                  theme,
                  Icons.notifications_rounded,
                  'Booking Notifications',
                  _notificationsEnabled,
                  (v) => setState(() => _notificationsEnabled = v),
                ),
              ]),
              const SizedBox(height: 12),
              _buildSection(theme, 'Support', [
                _menuItem(
                  theme,
                  Icons.help_outline_rounded,
                  'Help & Support',
                  'Contact VenueMate team',
                  AppTheme.info,
                  () => _showHelpSupportSheet(theme),
                ),
                _menuItem(
                  theme,
                  Icons.info_outline_rounded,
                  'About VenueMate',
                  'Version 1.0.0',
                  AppTheme.onSurfaceMuted,
                  () => _showAboutDialog(theme),
                ),
              ]),
              const SizedBox(height: 12),
              _buildSignOutButton(theme, context),
              const SizedBox(height: 20),
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
          Text('Owner Profile', style: theme.textTheme.headlineMedium),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primary,
              AppTheme.primaryLight,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final userName = _user?.name ?? 'Owner';
    final userEmail = _user?.email ?? 'email@example.com';
    final userPhone = _user?.phone ?? '+92 300 0000000';
    final profileImageUrl = _user?.profileImageUrl;
    final isVerified = _user?.isVerified ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryDark,
            AppTheme.primary,
            AppTheme.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: _uploadProfilePhoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: profileImageUrl != null
                          ? ClipOval(
                              child: CustomImageWidget(
                                imageUrl: profileImageUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.person_rounded,
                              size: 36, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 12,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userPhone,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showEditProfileSheet(theme),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _profileBadge(
                  isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                  isVerified ? 'Verified Owner' : 'Not Verified',
                ),
                const SizedBox(width: 8),
                _profileBadge(Icons.location_on_rounded, 'Gujranwala'),
                const SizedBox(width: 8),
                _profileBadge(
                    Icons.star_rounded, '${_stats['rating']} Rating'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueStatsRow(ThemeData theme) {
    final stats = [
      {
        'label': 'Venues',
        'value': _stats['venues']!,
        'icon': Icons.location_city_rounded
      },
      {
        'label': 'Bookings',
        'value': _stats['bookings']!,
        'icon': Icons.calendar_month_rounded
      },
      {
        'label': 'Revenue',
        'value': _stats['revenue']!,
        'icon': Icons.currency_rupee_rounded
      },
      {
        'label': 'Rating',
        'value': _stats['rating']!,
        'icon': Icons.star_rounded
      },
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: stats
            .map(
              (s) => Expanded(
                child: Column(
                  children: [
                    Icon(
                      s['icon'] as IconData,
                      size: 22,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s['value'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      s['label'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _menuItem(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchItem(
    ThemeData theme,
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryLighter,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(ThemeData theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showSignOutDialog(theme, context),
          icon: const Icon(
            Icons.logout_rounded,
            size: 18,
            color: AppTheme.error,
          ),
          label: Text(
            'Sign Out',
            style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.error),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(ThemeData theme, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: theme.textTheme.titleMedium),
        content: Text(
          'Are you sure you want to sign out from your owner account?',
          style: theme.textTheme.bodyMedium,
        ),
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
                  context,
                  AppRoutes.signUpLoginScreen,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
