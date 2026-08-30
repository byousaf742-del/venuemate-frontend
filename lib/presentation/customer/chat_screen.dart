import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'package:venuemate/core/services/user_service.dart';
import 'package:venuemate/presentation/customer/venues_screen.dart';

class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({super.key});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final res = await ApiClient.get('/messages/conversations');
      setState(() {
        _conversations = List<Map<String, dynamic>>.from(
            res['conversations'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
            Expanded(child: _buildConversationList(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Messages', style: theme.textTheme.headlineMedium),
                Text(
                  'Chat with venue owners',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Color.fromARGB(185, 0, 0, 0),
                  ),
                ),
              ],
            ),
          ),
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
          hintText: 'Search conversations...',
          hintStyle: const TextStyle(
          color: Color.fromARGB(185, 0, 0, 0), 
        ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Color.fromARGB(185, 0, 0, 0),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _searchQuery.isEmpty
        ? _conversations
        : _conversations
            .where((c) => c['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 52, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No conversations yet',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Start chatting from a booking or bid',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
        itemBuilder: (_, i) => _buildConversationTile(theme, filtered[i]),
      ),
    );
  }

  Future<void> _deleteConversation(Map<String, dynamic> conv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.delete('/messages/conversations/${conv['room_id']}');
      setState(() => _conversations
          .removeWhere((c) => c['room_id'] == conv['room_id']));
    } catch (_) {}
  }

  Widget _buildConversationTile(
      ThemeData theme, Map<String, dynamic> conv) {
    return GestureDetector(
      onLongPress: () => _deleteConversation(conv),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        onTap: () => _openChat(theme, conv),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.primaryLighter,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: (conv['context_image'] ?? conv['image']) != null
              ? ClipOval(
                  child: CustomImageWidget(
                    imageUrl: conv['context_image'] ?? conv['image'],
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.business_rounded,
                  color: AppTheme.primary, size: 26),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conv['context_name'] ?? conv['name'] ?? '',
                style: theme.textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(conv['time'] ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: (conv['unread'] ?? 0) > 0
                        ? AppTheme.primary
                        : AppTheme.onSurfaceMuted)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conv['name'] ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500)),
            Text(conv['last_message'] ?? conv['lastMessage'] ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: (conv['unread'] ?? 0) > 0
                      ? AppTheme.onSurface
                      : AppTheme.onSurfaceMuted,
                  fontWeight: (conv['unread'] ?? 0) > 0
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _openChat(ThemeData theme, Map<String, dynamic> conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(conversation: conv),
      ),
    ).then((_) => _loadConversations());
  }
}


class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;
  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  WebSocketChannel? _channel;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await UserService.getUser();
    _currentUserId = user?.id ?? '';
    await _loadMessages();
    _connectWebSocket();
  }

  Future<void> _loadMessages() async {
    try {
      final roomId = widget.conversation['room_id'];
      final res = await ApiClient.get('/messages/$roomId');
      setState(() {
        _messages.clear();
        _messages.addAll(
            List<Map<String, dynamic>>.from(res['messages'] ?? []));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _connectWebSocket() async {
    try {
      final token = await UserService.getAuthToken();
      if (token == null) return;
      final roomId = widget.conversation['room_id'];
      final baseUri = Uri.parse(ApiClient.baseUrl);
      final isSecure = baseUri.scheme == 'https';
      final uri = Uri(
        scheme: isSecure ? 'wss' : 'ws',
        host: baseUri.host,
        port: isSecure ? 443 : baseUri.port,
        path: '/ws/chat/$roomId',
        queryParameters: {'token': token},
      );
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (data) {
          final msg = jsonDecode(data as String);
          final isMe = msg['sender_id'] == _currentUserId;
          if (mounted) {
            setState(() {
              _messages.add({
                'id': msg['id'],
                'text': msg['text'],
                'isMe': isMe,
                'time': msg['time'],
              });
            });
            _scrollToBottom();
          }
        },
        onError: (_) => _reconnect(),
        onDone: () => _reconnect(),
      );
    } catch (_) {}
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _connectWebSocket();
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty || _isSending) return;
    final text = _msgController.text.trim();
    _msgController.clear();
    setState(() => _isSending = true);

    try {
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({
          'content': text,
          'receiver_id': widget.conversation['other_user_id'] ??
              widget.conversation['receiver_id'] ?? '',
        }));
      } else {
        await ApiClient.post('/messages', {
          'room_id': widget.conversation['room_id'],
          'receiver_id': widget.conversation['other_user_id'] ??
              widget.conversation['receiver_id'] ?? '',
          'content': text,
          'type': 'text',
        });
        setState(() {
          _messages.add({'text': text, 'isMe': true, 'time': 'Now'});
        });
        _scrollToBottom();
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildContextBanner(ThemeData theme) {
    final conv = widget.conversation;
    final contextType = conv['context_type'] ?? '';
    final contextName = conv['context_name'] ?? '';
    if (contextName.isEmpty) return const SizedBox.shrink();

    IconData icon;
    if (contextType == 'booking') {
      icon = Icons.event_available_rounded;
    } else if (contextType == 'bid') {
      icon = Icons.gavel_rounded;
    } else {
      icon = Icons.business_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.primaryLighter,
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              contextType == 'booking'
                  ? 'Booking — $contextName'
                  : contextType == 'bid'
                      ? 'Bid — $contextName'
                      : 'Enquiry — $contextName',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conv = widget.conversation;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                shape: BoxShape.circle,
              ),
              child: (conv['context_image'] ?? conv['image']) != null
                  ? ClipOval(
                      child: CustomImageWidget(
                        imageUrl: conv['context_image'] ?? conv['image'],
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.business_rounded,
                      color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv['context_name'] ?? conv['name'] ?? '',
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    conv['name'] ?? '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () async {
              try {
                final otherId = conv['other_user_id'] ?? conv['receiver_id'] ?? '';
                if (otherId.isEmpty) return;
                final res = await ApiClient.get('/users/$otherId/phone');
                final phone = res['phone'] ?? '';
                if (phone.isNotEmpty) {
                  final uri = Uri(scheme: 'tel', path: phone);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone number not available')),
                    );
                  }
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not retrieve phone number')),
                  );
                }
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'view_venue') {
                final venueId = conv['room_id'].toString().split(':').length > 1
                    ? conv['room_id'].toString().split(':')[1]
                    : '';
                if (venueId.isNotEmpty) {
                  try {
                    final res = await ApiClient.get('/venues/$venueId');
                    final v = res['venue'];
                    if (v != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VenueDetailScreen(
                            venue: {
                              'id': v['id'],
                              'name': v['name'],
                              'location': v['location']?['address'] ?? '',
                              'type': v['type'] ?? '',
                              'capacity': v['capacity']?['max'] ?? 0,
                              'price': v['pricing']?['base_per_day'] ?? 0,
                              'rating': (v['rating'] ?? 0.0).toDouble(),
                              'reviews': v['review_count'] ?? 0,
                              'owner_id': v['owner_id'] ?? '',
                              'image': (v['media'] != null && (v['media'] as List).isNotEmpty)
                                  ? v['media'][0]['url'] : '',
                              'images': (v['media'] as List?)
                                  ?.map((m) => m['url'].toString()).toList() ?? [],
                            },
                            currentUserId: '',
                          ),
                        ),
                      );
                    }
                  } catch (_) {}
                }
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Delete Conversation'),
                    content: const Text(
                        'Are you sure you want to delete this conversation?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  try {
                    await ApiClient.delete(
                        '/messages/conversations/${conv['room_id']}');
                    if (mounted) Navigator.pop(context);
                  } catch (_) {}
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'view_venue',
                child: Row(
                  children: [
                    Icon(Icons.location_city_rounded,
                        color: AppTheme.primary, size: 18),
                    SizedBox(width: 10),
                    Text('View Venue'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 18),
                    SizedBox(width: 10),
                    Text('Delete Conversation',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildContextBanner(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text('No messages yet. Say hello!',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceMuted)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _buildMessage(theme, _messages[i]),
                      ),
          ),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildMessage(ThemeData theme, Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(msg['text'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: isMe ? Colors.white : AppTheme.onSurface,
                    height: 1.4)),
            const SizedBox(height: 4),
            Text(msg['time'] ?? '',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withAlpha(179)
                        : AppTheme.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(
          color: Color.fromARGB(185, 0, 0, 0), 
        ),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
