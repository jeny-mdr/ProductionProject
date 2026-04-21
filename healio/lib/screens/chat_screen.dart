import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUsername;
  final String otherName;
  final String? otherPicUrl;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherName,
    this.otherPicUrl,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  ChatProvider? _chatProvider;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async {
      context.read<ChatProvider>().connect(
        widget.otherUserId,
        auth.token ?? '',
        auth.user?['username'] ?? '',
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) await _markAsRead();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider ??= context.read<ChatProvider>();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _chatProvider?.disconnect();
    super.dispose();
  }

  void _scrollBottom() {
    SchedulerBinding.instance
        .addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration:
          const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _msgCtrl.clear();
    _scrollBottom();
  }

  Future<void> _markAsRead() async {
    final token = context.read<AuthProvider>().token;
    try {
      final res = await http.get(
        Uri.parse(kChatRoomsUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final rooms = List<dynamic>.from(jsonDecode(res.body));
        final room = rooms.firstWhere(
              (r) => r['other_user_id'].toString() == widget.otherUserId,
          orElse: () => null,
        );
        if (room != null) {
          final roomId = room['room_id'] as int;
          await http.post(
            Uri.parse(kMarkReadUrl(roomId)),
            headers: {'Authorization': 'Bearer $token'},
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx',
        'jpg', 'jpeg', 'png', 'gif'
      ],
      allowMultiple: false,
    );

    if (result == null) return;
    final file = result.files.single;
    if (file.path == null) return;

    final auth  = context.read<AuthProvider>();
    final token = auth.token ?? '';

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(kChatUploadUrl),
      );
      request.headers['Authorization'] =
      'Bearer $token';
      request.fields['other_user_id'] =
          widget.otherUserId;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', file.path!,
        ),
      );

      final response = await request.send();
      if (response.statusCode == 201) {
        // ── NEW: read response and add file message ──
        final responseBody =
        await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        context.read<ChatProvider>().addFileMessage(
          fileName:    data['file_name'],
          fileUrl:     data['file_url'],
          messageType: data['message_type'],
          sender:      auth.user?['username'] ?? '',
        );

        // ── NEW: reconnect if WebSocket dropped ──
        final chat = context.read<ChatProvider>();
        if (!chat.isConnected) {
          await chat.connect(
            widget.otherUserId,
            token,
            auth.user?['username'] ?? '',
          );
        }
        _scrollBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File upload failed'),
              backgroundColor: HealioColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('File upload error: $e');
    }
  }

  void _showPrescriptionDialog() {
    final auth      = context.read<AuthProvider>();
    final prescCtrl = TextEditingController();
    bool  saving    = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: HealioColors.primaryLight,
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: HealioColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text('Write Prescription',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HealioColors.textDark,
                )),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'For: ${widget.otherName}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: HealioColors.textMid,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prescCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                  'e.g. Take Paracetamol 500mg twice daily…',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: HealioColors.textLight),
                  filled: true,
                  fillColor: HealioColors.bgInput,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: HealioColors.error)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color:
                      HealioColors.textMid)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                HealioColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                        12)),
                minimumSize:
                const Size(0, 40),
              ),
              onPressed: saving
                  ? null
                  : () async {
                final text =
                prescCtrl.text.trim();
                if (text.isEmpty) {
                  setS(() => error =
                  'Please write the prescription.');
                  return;
                }
                setS(() {
                  saving = true;
                  error  = null;
                });

                try {
                  final res =
                  await http.post(
                    Uri.parse(
                        kSavePrescriptionUrl),
                    headers: {
                      'Content-Type':
                      'application/json',
                      'Authorization':
                      'Bearer ${auth.token}',
                    },
                    body: jsonEncode({
                      'patient_id':
                      int.parse(widget
                          .otherUserId),
                      'prescription': text,
                    }),
                  );

                  if (res.statusCode ==
                      201) {
                    context
                        .read<ChatProvider>()
                        .sendMessage(
                        '📋 Prescription:\n$text');
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _showSuccessSnack();
                    }
                  } else {
                    setS(() {
                      saving = false;
                      error =
                      'Failed to save. Try again.';
                    });
                  }
                } catch (_) {
                  setS(() {
                    saving = false;
                    error =
                    'Network error. Try again.';
                  });
                }
              },
              icon: saving
                  ? const SizedBox(
                  width: 14, height: 14,
                  child:
                  CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2))
                  : const Icon(
                  Icons.save_rounded,
                  size: 16),
              label: Text(
                saving
                    ? 'Saving...'
                    : 'Save to Blockchain',
                style:
                GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: HealioColors.success,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Prescription saved to blockchain!',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.read<AuthProvider>();
    final chat  = context.watch<ChatProvider>();
    final isDoc = auth.isDoctor;
    _scrollBottom();

    return Scaffold(
      backgroundColor: const Color(0xFFEDF7F2),
      appBar: AppBar(
        backgroundColor: HealioColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white),
          onPressed: () =>
              Navigator.pop(context),
        ),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: widget.otherPicUrl != null &&
                widget.otherPicUrl!.isNotEmpty
                ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.otherPicUrl!.startsWith('http')
                    ? widget.otherPicUrl!
                    : '$kBaseUrl${widget.otherPicUrl}',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Text(
                  widget.otherName[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            )
                : Text(
              widget.otherName[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                isDoc
                    ? widget.otherName
                    : 'Dr. ${widget.otherName}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Row(children: [
                Icon(Icons.circle,
                    size: 7,
                    color: chat.isConnected
                        ? HealioColors.online
                        : Colors.white38),
                const SizedBox(width: 4),
                Text(
                  chat.isConnecting
                      ? 'Connecting…'
                      : chat.isConnected
                      ? 'Online'
                      : 'Offline',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white
                        .withOpacity(0.85),
                  ),
                ),
              ]),
            ],
          ),
        ]),
        actions: [
          if (isDoc)
            IconButton(
              tooltip: 'Write Prescription',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.2),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: const Icon(
                    Icons
                        .medical_services_rounded,
                    color: Colors.white,
                    size: 20),
              ),
              onPressed:
              _showPrescriptionDialog,
            ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(children: [
        // Messages
        Expanded(
          child: chat.isConnecting
              ? const Center(
            child: CircularProgressIndicator(
                color: HealioColors.primary),
          )
              : chat.messages.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(
                    Icons
                        .chat_bubble_outline_rounded,
                    size: 56,
                    color: HealioColors
                        .primaryMid),
                const SizedBox(height: 12),
                Text(
                    'Start the conversation',
                    style: GoogleFonts.poppins(
                        color: HealioColors
                            .textMid)),
              ],
            ),
          )
              : ListView.builder(
            controller: _scrollCtrl,
            padding:
            const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14),
            itemCount:
            chat.messages.length,
            itemBuilder: (_, i) {
              final m =
              chat.messages[i];
              final prev = i > 0
                  ? chat.messages[i - 1]
                  : null;
              final showDate =
                  prev == null ||
                      !_sameDay(
                          prev.timestamp,
                          m.timestamp);
              return Column(children: [
                if (showDate)
                  _DateDivider(
                      m.timestamp),
                _Bubble(msg: m),
              ]);
            },
          ),
        ),

        // Input bar
        Container(
          color: HealioColors.bgCard,
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            top: 10,
            bottom:
            MediaQuery.of(context).padding.bottom +
                10,
          ),
          child: Row(children: [
            // Attachment button
            GestureDetector(
              onTap: _pickAndSendFile,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: HealioColors.bgInput,
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                      color: HealioColors.border),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: HealioColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Text field
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                textCapitalization:
                TextCapitalization.sentences,
                maxLines: null,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  fillColor: HealioColors.bgInput,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Send button
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46, height: 46,
                decoration: const BoxDecoration(
                  color: HealioColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year &&
          a.month == b.month &&
          a.day == b.day;
}

// ── Bubble ──────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final dynamic msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isMe           = msg.isMe as bool;
    final text           = msg.message as String;
    final isPrescription =
    text.startsWith('📋 Prescription:');
    final msgType =
        msg.messageType as String? ?? 'text';
    final fileUrl =
    msg.fileUrl as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment:
        CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor:
              HealioColors.primaryLight,
              child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 13,
                  color: HealioColors.primary),
            ),
            const SizedBox(width: 7),
          ],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth:
                  MediaQuery.of(context)
                      .size
                      .width *
                      0.66,
                ),
                padding: msgType == 'image'
                    ? EdgeInsets.zero
                    //? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isPrescription
                      ? (isMe
                      ? HealioColors
                      .primaryDark
                      : HealioColors
                      .primaryLight)
                      : (isMe
                      ? HealioColors.primary
                      : HealioColors.bgCard),
                  borderRadius: BorderRadius.only(
                    topLeft:
                    const Radius.circular(18),
                    topRight:
                    const Radius.circular(18),
                    bottomLeft: Radius.circular(
                        isMe ? 18 : 4),
                    bottomRight: Radius.circular(
                        isMe ? 4 : 18),
                  ),
                  border: isPrescription
                      ? Border.all(
                      color:
                      HealioColors.primary,
                      width: 1.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: msgType == 'file' ||
                    msgType == 'image'
                    ? _FileWidget(
                  text:    text,
                  fileUrl: fileUrl,
                  isMe:    isMe,
                  isImage:
                  msgType == 'image',
                )
                    : isPrescription
                    ? _PrescriptionContent(
                    text: text,
                    isMe: isMe)
                    : Text(
                  text,
                  style:
                  GoogleFonts.poppins(
                    fontSize: 14,
                    color: isMe
                        ? Colors.white
                        : HealioColors
                        .textDark,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                    () {
                  final dt =
                  (msg.timestamp as DateTime)
                      .toLocal();
                  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                }(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: HealioColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── File widget ─────────────────────────────────────
class _FileWidget extends StatelessWidget {
  final String  text;
  final String? fileUrl;
  final bool    isMe;
  final bool    isImage;

  const _FileWidget({
    required this.text,
    required this.fileUrl,
    required this.isMe,
    required this.isImage,
  });

  @override
  Widget build(BuildContext context) {
    final fileName =
    text.replaceFirst('📎 ', '');

    if (isImage && fileUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: fileUrl!,
          width: 200,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
          const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                  color: HealioColors.primary),
            ),
          ),
          errorWidget: (_, __, ___) =>
          const Icon(
              Icons.broken_image_rounded,
              color: HealioColors.textLight),
        ),
      );
    }

    return GestureDetector(
      onTap: fileUrl != null
          ? () async {
        final uri = Uri.parse(fileUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri,
              mode: LaunchMode
                  .externalApplication);
        }
      }
          : null,
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withOpacity(0.2)
                : HealioColors.primaryLight,
            borderRadius:
            BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.insert_drive_file_rounded,
            color: isMe
                ? Colors.white
                : HealioColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isMe
                      ? Colors.white
                      : HealioColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Tap to open',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white70
                      : HealioColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Prescription content ────────────────────────────
class _PrescriptionContent extends StatelessWidget {
  final String text;
  final bool   isMe;
  const _PrescriptionContent(
      {required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.medical_services_rounded,
              size: 14,
              color: isMe
                  ? Colors.white
                  : HealioColors.primary),
          const SizedBox(width: 4),
          Text('Prescription',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isMe
                    ? Colors.white
                    : HealioColors.primary,
              )),
          const SizedBox(width: 4),
          Icon(Icons.verified_rounded,
              size: 12,
              color: isMe
                  ? Colors.white70
                  : HealioColors.primaryDark),
          const SizedBox(width: 2),
          Text('Blockchain',
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: isMe
                    ? Colors.white70
                    : HealioColors.textMid,
              )),
        ]),
        const SizedBox(height: 6),
        Container(
            height: 1,
            color: isMe
                ? Colors.white24
                : HealioColors.border),
        const SizedBox(height: 6),
        Text(
          text.replaceFirst(
              '📋 Prescription:\n', ''),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isMe
                ? Colors.white
                : HealioColors.textDark,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── Date divider ────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider(this.date);

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final label = date.day == now.day &&
        date.month == now.month
        ? 'Today'
        : '${date.day}/${date.month}/${date.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 12),
      child: Row(children: [
        Expanded(
            child: Divider(
                color: HealioColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12),
          child: Text(label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: HealioColors.textLight,
              )),
        ),
        Expanded(
            child: Divider(
                color: HealioColors.border)),
      ]),
    );
  }
}