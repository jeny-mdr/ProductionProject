import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUsername;
  final String otherName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();

    // Fetch profile first to ensure username is loaded
    auth.fetchProfile().then((_) {
      if (mounted) {
        context.read<ChatProvider>().connect(
          widget.otherUserId,
          auth.token ?? '',
          auth.user?['username'] ?? '',
        );
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    context.read<ChatProvider>().disconnect();
    super.dispose();
  }

  void _scrollBottom() {
    SchedulerBinding.instance
        .addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
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

  // ── Prescription dialog (doctor only) ──────────
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
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: HealioColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: HealioColors.primary, size: 18,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  'e.g. Take Paracetamol 500mg twice daily for 5 days...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: HealioColors.textLight),
                  filled: true,
                  fillColor: HealioColors.bgInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: HealioColors.textMid)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: HealioColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 40),
              ),
              onPressed: saving
                  ? null
                  : () async {
                final text = prescCtrl.text.trim();
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
                  final res = await http.post(
                    Uri.parse(kSavePrescriptionUrl),
                    headers: {
                      'Content-Type':  'application/json',
                      'Authorization': 'Bearer ${auth.token}',
                    },
                    body: jsonEncode({
                      'patient_id': int.parse(
                          widget.otherUserId),
                      'prescription': text,
                    }),
                  );

                  if (res.statusCode == 201) {
                    // Also send as chat message
                    context.read<ChatProvider>()
                        .sendMessage('📋 Prescription:\n$text');
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _showSuccessSnack();
                    }
                  } else {
                    setS(() {
                      saving = false;
                      error  = 'Failed to save. Try again.';
                    });
                  }
                } catch (_) {
                  setS(() {
                    saving = false;
                    error  = 'Network error. Try again.';
                  });
                }
              },
              icon: saving
                  ? const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(
                saving ? 'Saving...' : 'Save to Blockchain',
                style: GoogleFonts.poppins(fontSize: 13),
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
                  color: Colors.white, fontSize: 13)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.read<AuthProvider>();
    final chat   = context.watch<ChatProvider>();
    final isDoc  = auth.isDoctor;
    _scrollBottom();

    return Scaffold(
      backgroundColor: const Color(0xFFEDF7F2),
      appBar: AppBar(
        backgroundColor: HealioColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ]),
            ],
          ),
        ]),
        // Prescription button — doctors only
        actions: [
          if (isDoc)
            IconButton(
              tooltip: 'Write Prescription',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: _showPrescriptionDialog,
            ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(children: [
        Expanded(
          child: chat.messages.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 56,
                    color: HealioColors.primaryMid),
                const SizedBox(height: 12),
                Text('Start the conversation',
                    style: GoogleFonts.poppins(
                        color: HealioColors.textMid)),
              ],
            ),
          )
              : ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            itemCount: chat.messages.length,
            itemBuilder: (_, i) {
              final m    = chat.messages[i];
              final prev = i > 0 ? chat.messages[i - 1] : null;
              final showDate = prev == null ||
                  !_sameDay(prev.timestamp, m.timestamp);
              return Column(children: [
                if (showDate) _DateDivider(m.timestamp),
                _Bubble(msg: m),
              ]);
            },
          ),
        ),

        // Input bar
        Container(
          color: HealioColors.bgCard,
          padding: EdgeInsets.only(
            left: 14, right: 14, top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  fillColor: HealioColors.bgInput,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46, height: 46,
                decoration: const BoxDecoration(
                  color: HealioColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Bubble ─────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final dynamic msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isMe        = msg.isMe as bool;
    final text        = msg.message as String;
    final isPrescription = text.startsWith('📋 Prescription:');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: HealioColors.primaryLight,
              child: const Icon(Icons.local_hospital_rounded,
                  size: 13, color: HealioColors.primary),
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
                  MediaQuery.of(context).size.width * 0.66,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isPrescription
                      ? (isMe
                      ? HealioColors.primaryDark
                      : HealioColors.primaryLight)
                      : (isMe
                      ? HealioColors.primary
                      : HealioColors.bgCard),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  border: isPrescription
                      ? Border.all(
                      color: HealioColors.primary,
                      width: 1.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPrescription) ...[
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
                            : HealioColors.border,
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      isPrescription
                          ? text.replaceFirst(
                          '📋 Prescription:\n', '')
                          : text,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isMe
                            ? Colors.white
                            : HealioColors.textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                    () {
                  final dt =
                  (msg.timestamp as DateTime).toLocal();
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

// ── Date divider ───────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider(this.date);

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final label = date.day == now.day && date.month == now.month
        ? 'Today'
        : '${date.day}/${date.month}/${date.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Divider(color: HealioColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: HealioColors.textLight,
              )),
        ),
        Expanded(child: Divider(color: HealioColors.border)),
      ]),
    );
  }
}