import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../data/chat_repository.dart';
import '../providers/chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String deliveryRequestId;
  final String roomId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String itemType;
  final String pickup;
  final String drop;

  const ChatScreen({
    super.key,
    required this.deliveryRequestId,
    required this.roomId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.itemType,
    required this.pickup,
    required this.drop,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  bool _showInfo = false;
  
  // Audio Recording State
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  bool _isTextFieldEmpty = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(jump: true);
      _markRead();
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });
    _messageController.addListener(() {
      final isEmpty = _messageController.text.trim().isEmpty;
      if (_isTextFieldEmpty != isEmpty) {
        setState(() => _isTextFieldEmpty = isEmpty);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _markRead() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(chatRepositoryProvider).markMessagesRead(
            roomId: widget.roomId,
            recipientId: user.id,
          );
    }
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scrollController.hasClients) return;
    if (jump) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    } else {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            roomId: widget.roomId,
            senderId: user.id,
            message: text,
            messageType: 'text',
          );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        _messageController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });

      if (path != null) {
        await _sendAudioMessage(path);
      }
    } else {
      // Start recording
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Microphone permission required')),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: tempPath,
      );

      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _sendAudioMessage(String path) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      final repo = ref.read(chatRepositoryProvider);
      final publicUrl = await repo.uploadAudioMessage(widget.roomId, path);
      
      await repo.sendMessage(
        roomId: widget.roomId,
        senderId: user.id,
        message: publicUrl,
        messageType: 'audio',
      );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send audio: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
      
      // Cleanup temp file
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return '';
    }
  }

  String _formatDateLabel(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'TODAY';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (dt.year == yesterday.year &&
          dt.month == yesterday.month &&
          dt.day == yesterday.day) {
        return 'YESTERDAY';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final myId = user?.id ?? '';
    final messagesAsync = ref.watch(chatMessagesProvider(widget.roomId));

    ref.listen(chatMessagesProvider(widget.roomId), (_, next) {
      if (next.hasValue) {
        Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
        _markRead();
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Color(0xFFEBE3D5), // WhatsApp wallpaper
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            // ── Delivery Info Banner (collapsible) ──────────────────────
            _buildInfoBanner(),

            // ── Messages ────────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: messagesAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error loading chat: $e',
                          style:
                              TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center),
                    ),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                'Say hello! 👋',
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    String? lastDate;
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender_id'] == myId;
                        final time = _formatTime(msg['created_at']);
                        final dateLabel =
                            _formatDateLabel(msg['created_at']);
                        final isRead = msg['is_read'] as bool? ?? false;

                        Widget? dateDivider;
                        if (dateLabel != lastDate) {
                          lastDate = dateLabel;
                          dateDivider = _buildDateChip(dateLabel);
                        }

                        return Column(
                          children: [
                            if (dateDivider != null) dateDivider,
                            _MessageBubble(
                              isMe: isMe,
                              message: msg['message'] as String? ?? '',
                              messageType: msg['message_type'] as String? ?? 'text',
                              time: time,
                              isRead: isRead,
                              otherAvatar: widget.otherUserAvatar,
                              otherName: widget.otherUserName,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // ── Input Bar ───────────────────────────────────────────────
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final initials = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : '?';

    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () => setState(() => _showInfo = !_showInfo),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? Text(initials,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15))
                  : null,
            ),
            SizedBox(width: 0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.otherUserName,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        letterSpacing: 0.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 0),
                      Text(
                        'Match Active',
                        style: TextStyle(
                            color: Color(0xFF86EFAC),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: Color(0xFFFFF8E1),
      padding: _showInfo
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
          : EdgeInsets.zero,
      height: _showInfo ? null : 0,
      child: _showInfo
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      color: AppTheme.primaryColor, size: 16),
                ),
                SizedBox(width: 0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.itemType,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                            color: AppTheme.primaryColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.pickup}  →  ${widget.drop}',
                        style: TextStyle(
                            fontSize: 10.sp, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'Match Found',
                    style: TextStyle(
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDateChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            label,
            style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        color: Color(0xFFEBE3D5),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Text field ────────────────────────────────────────────
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(width: 0),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(fontSize: 13.sp, height: 1.4),
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(width: 0),
                  ],
                ),
              ),
            ),
            SizedBox(width: 0),
            // ── Send / Mic button ─────────────────────────────────────
            GestureDetector(
              onTap: _isTextFieldEmpty && !_isSending ? _toggleRecording : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isRecording ? 56 : 48,
                height: _isRecording ? 56 : 48,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.redAccent : AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.redAccent : AppTheme.primaryColor).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _isSending
                    ? Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        _isRecording ? Icons.stop_rounded : (_isTextFieldEmpty ? Icons.mic_rounded : Icons.send_rounded),
                        color: Colors.white, size: _isRecording ? 28 : 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Bubble Widget ─────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  final String messageType;
  final String time;
  final bool isRead;
  final String? otherAvatar;
  final String otherName;

  const _MessageBubble({
    required this.isMe,
    required this.message,
    this.messageType = 'text',
    required this.time,
    required this.isRead,
    required this.otherAvatar,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 2,
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other person
          if (!isMe) ...[
            CircleAvatar(
              radius: 11.r,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage:
                  otherAvatar != null ? NetworkImage(otherAvatar!) : null,
              child: otherAvatar == null
                  ? Text(
                      otherName.isNotEmpty
                          ? otherName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            SizedBox(width: 0),
          ],

          // Bubble
          Flexible(
            child: CustomPaint(
              painter: _BubbleTailPainter(
                isMe: isMe,
                color: isMe
                    ? Color(0xFFDCF8C6) // WhatsApp green-ish
                    : Colors.white,
              ),
              child: Container(
                margin: EdgeInsets.only(
                  left: isMe ? 0 : 6,
                  right: isMe ? 6 : 0,
                ),
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                decoration: BoxDecoration(
                  color: isMe
                      ? Color(0xFFDCF8C6) // WhatsApp sent bubble
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isMe ? 12 : 2),
                    bottomRight: Radius.circular(isMe ? 2 : 12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (messageType == 'audio')
                      _AudioPlayerWidget(
                        audioUrl: message,
                        isMe: isMe,
                      )
                    else
                      Text(
                        message,
                        style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF111B21),
                            height: 1.35),
                      ),
                    const SizedBox(height: 2),
                    // Time + read receipt
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey.shade600,
                              height: 1),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 3),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 12.sp,
                            color: isRead
                                ? Color(0xFF53BDEB) // WhatsApp blue ticks
                                : Colors.grey.shade500,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bubble Tail Painter ───────────────────────────────────────────────────────

class _BubbleTailPainter extends CustomPainter {
  final bool isMe;
  final Color color;
  _BubbleTailPainter({required this.isMe, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isMe) {
      // Right tail
      path.moveTo(size.width + 6, size.height - 4);
      path.lineTo(size.width - 2, size.height - 12);
      path.lineTo(size.width - 2, size.height - 4);
    } else {
      // Left tail
      path.moveTo(-6, size.height - 4);
      path.lineTo(2, size.height - 12);
      path.lineTo(2, size.height - 4);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) =>
      old.isMe != isMe || old.color != color;
}

// ─── Audio Player Widget ───────────────────────────────────────────────────────

class _AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const _AudioPlayerWidget({required this.audioUrl, required this.isMe});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setUrl(widget.audioUrl);
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _audioPlayer.seek(Duration.zero);
              _audioPlayer.pause();
            }
          });
        }
      });
      _audioPlayer.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });
      _audioPlayer.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
    } catch (e) {
      if (mounted) setState(() => _isError = true);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Error loading audio', style: TextStyle(color: Colors.red, fontSize: 12)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (_isPlaying) {
              _audioPlayer.pause();
            } else {
              _audioPlayer.play();
            }
          },
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isMe ? Color(0xFF4ADE80) : AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        SizedBox(width: 8),
        Container(
          width: 140,
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
              activeTrackColor: widget.isMe ? Color(0xFF166534) : AppTheme.primaryColor,
              inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
              thumbColor: widget.isMe ? Color(0xFF166534) : AppTheme.primaryColor,
            ),
            child: Slider(
              min: 0,
              max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
              value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
              onChanged: (val) {
                _audioPlayer.seek(Duration(milliseconds: val.toInt()));
              },
            ),
          ),
        ),
        SizedBox(width: 4),
        Text(
          _formatDuration(_position.inMilliseconds > 0 ? _position : _duration),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
