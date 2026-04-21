import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() =>
      _ChatListScreenState();
}

class _ChatListScreenState
    extends State<ChatListScreen> {
  List<dynamic> _rooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final token =
        context.read<AuthProvider>().token;
    try {
      final res = await http.get(
        Uri.parse(kChatRoomsUrl),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );
      if (res.statusCode == 200) {
        setState(() {
          _rooms = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error =
          'Server error ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Cannot reach server';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealioColors.bg,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: HealioColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white),
          onPressed: () =>
              Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white),
            onPressed: _fetch,
          ),
        ],
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(
              color: HealioColors.primary))
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: HealioColors
                    .textLight),
            const SizedBox(height: 12),
            Text(_error!,
                style: GoogleFonts.poppins(
                    color: HealioColors
                        .textMid)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetch,
              style: ElevatedButton
                  .styleFrom(
                minimumSize:
                const Size(120, 44),
              ),
              child:
              const Text('Retry'),
            ),
          ],
        ),
      )
          : _rooms.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Icon(
              Icons
                  .chat_bubble_outline_rounded,
              size: 60,
              color: HealioColors
                  .primaryMid,
            ),
            const SizedBox(
                height: 12),
            Text(
              'No conversations yet',
              style:
              GoogleFonts.poppins(
                fontSize: 15,
                fontWeight:
                FontWeight.w600,
                color: HealioColors
                    .textMid,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chat a doctor to get started',
              style:
              GoogleFonts.poppins(
                fontSize: 13,
                color: HealioColors
                    .textLight,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        color: HealioColors.primary,
        onRefresh: _fetch,
        child: ListView.builder(
          itemCount: _rooms.length,
          itemBuilder: (_, i) =>
              _RoomTile(
                  room: _rooms[i]),
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final Map<String, dynamic> room;
  const _RoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final otherName =
        room['other_username']?.toString()
            ?? 'Unknown';
    final otherId =
        room['other_user_id']?.toString()
            ?? '0';
    final otherUser = otherName;

    final lastMsg =
        room['last_message'] as String?
            ?? 'Tap to chat';
    final unread =
        room['unread_count'] as int? ?? 0;
    final lastTime =
    room['last_message_time'] as String?;

    String timeLabel = '';
    if (lastTime != null) {
      try {
        final dt =
        DateTime.parse(lastTime).toLocal();
        final now = DateTime.now();
        if (dt.day == now.day) {
          timeLabel =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else {
          timeLabel = '${dt.day}/${dt.month}';
        }
      } catch (_) {}
    }

    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(
          context, '/chat',
          arguments: {
            'otherUserId':   otherId,
            'otherUsername': otherUser,
            'otherName':     otherName,
          },
        );
      },

      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: HealioColors.bgCard,
          border: Border(
            bottom: BorderSide(
                color: HealioColors.border),
          ),
        ),
        child: Row(children: [
          // Avatar with unread badge
          Stack(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor:
              HealioColors.primaryLight,
              child: Text(
                otherName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: HealioColors.primary,
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                    color: HealioColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unread > 9
                          ? '9+'
                          : '$unread',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 14),

          // Name + last message
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      otherName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: unread > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color:
                        HealioColors.textDark,
                      ),
                    ),
                  ),
                  if (timeLabel.isNotEmpty)
                    Text(
                      timeLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: unread > 0
                            ? HealioColors.primary
                            : HealioColors.textLight,
                        fontWeight: unread > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                ]),
                const SizedBox(height: 3),
                Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: unread > 0
                        ? HealioColors.textDark
                        : HealioColors.textLight,
                    fontWeight: unread > 0
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}