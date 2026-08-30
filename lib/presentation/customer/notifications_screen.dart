import 'package:flutter/material.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigate;
  const NotificationsScreen({super.key, this.onNavigate});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/notifications');
      final list = (res['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
      if (mounted) setState(() { _notifications = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.put('/notifications/read-all', {});
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
    } catch (_) {}
  }

  Future<void> _markOneRead(NotificationModel n) async {
    if (n.isRead) return;
    try {
      await ApiClient.put('/notifications/${n.id}/read', {});
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx != -1) _notifications[idx] = n.copyWith(isRead: true);
      });
    } catch (_) {}
  }

  void _onTap(NotificationModel n) {
    _markOneRead(n);
    _navigate(n);
  }

  void _navigate(NotificationModel n) {
    final et = n.entityType;
    if (et == null) return;

    int? tabIndex;

    // Customer tabs: Home=0, Venues=1, Bookings=2, Requests=3, Chat=4, Account=5
    // Owner tabs:    Dashboard=0, Venues=1, Bookings=2, Requests=3, Chat=4, Account=5
    switch (et) {
      case 'booking':
        tabIndex = 2; // Bookings tab (both customer & owner)
        break;
      case 'bid':
      case 'quotation':
        tabIndex = 3; // Requests tab (both customer & owner)
        break;
      case 'venue':
        tabIndex = 1; // Venues tab (both)
        break;
      case 'message':
      case 'chat':
        tabIndex = 4; // Chat tab (both)
        break;
    }

    if (tabIndex != null && widget.onNavigate != null) {
      Navigator.pop(context);
      widget.onNavigate!(tabIndex);
    } else {
      Navigator.pop(context);
    }
  }

  IconData _iconFor(String type) {
    if (type.contains('booking')) return Icons.calendar_month_rounded;
    if (type.contains('bid') || type.contains('quotation')) return Icons.request_quote_rounded;
    if (type.contains('venue')) return Icons.location_city_rounded;
    if (type.contains('message') || type.contains('chat')) return Icons.chat_bubble_rounded;
    if (type.contains('announcement')) return Icons.campaign_rounded;
    return Icons.notifications_rounded;
  }

  Color _colorFor(String type) {
    if (type.contains('booking')) return Colors.green;
    if (type.contains('bid') || type.contains('quotation')) return Colors.orange;
    if (type.contains('venue')) return AppTheme.primary;
    if (type.contains('message') || type.contains('chat')) return Colors.blue;
    if (type.contains('announcement')) return Colors.purple;
    return AppTheme.primary;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
            if (unread > 0)
              Text('$unread unread', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) => _buildTile(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildTile(NotificationModel n) {
    final color = _colorFor(n.type);
    return InkWell(
      onTap: () => _onTap(n),
      child: Container(
        color: n.isRead ? Colors.transparent : AppTheme.primary.withAlpha(15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(n.type), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.body,
                    style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(n.createdAt),
                    style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: AppTheme.onSurfaceMuted),
          const SizedBox(height: 16),
          Text('No notifications yet', style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('You\'ll be notified about bookings, bids, and more', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
