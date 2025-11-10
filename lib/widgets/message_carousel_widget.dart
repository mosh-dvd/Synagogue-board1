import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synagogue_display/data/models.dart';
import 'package:path/path.dart' as p;

class MessageCarouselWidget extends StatefulWidget {
  final List<Message> messages;
  const MessageCarouselWidget({Key? key, required this.messages}) : super(key: key);

  @override
  _MessageCarouselWidgetState createState() => _MessageCarouselWidgetState();
}

class _MessageCarouselWidgetState extends State<MessageCarouselWidget> {
  Timer? _timer;
  final PageController _pageController = PageController();
  String _mediaPath = '';

  @override
  void initState() {
    super.initState();
    _init();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final appDir = await getApplicationSupportDirectory();
    if (mounted) {
      setState(() {
        _mediaPath = p.join(appDir.path, 'media');
      });
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(MessageCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.map((e) => e.id).join(',') != oldWidget.messages.map((e) => e.id).join(',')) {
       if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (!mounted || widget.messages.length <= 1) return;
    
    void scheduleNext() {
      if (!mounted) return;
      final currentIndex = _pageController.page?.round() ?? 0;
      final currentMessage = widget.messages[currentIndex % widget.messages.length];
      final durationInSeconds = currentMessage.duration > 0 ? currentMessage.duration : 10;
      _timer = Timer(Duration(seconds: durationInSeconds), () {
        if (!mounted) return;
        final nextPage = ((_pageController.page?.round() ?? 0) + 1) % widget.messages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
        scheduleNext();
      });
    }
    scheduleNext();
  }

  Widget _buildMessageContent(Message message) {
    if (_mediaPath.isEmpty && message.type != MessageType.TEXT) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (message.type) {
      case MessageType.TEXT:
        return Container(
          color: Colors.blueGrey[900],
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                message.content,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      case MessageType.IMAGE:
      case MessageType.PDF:
        final file = File(p.join(_mediaPath, message.content));
        return Container(
          color: Colors.black,
          child: file.existsSync()
              ? Image.file(file, fit: BoxFit.contain)
              : Center(child: Text('קובץ התמונה לא נמצא:\n${message.content}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 24))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(child: Text('אין הודעות פעילות', style: TextStyle(fontSize: 24, color: Colors.grey)));
    }
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        return _buildMessageContent(widget.messages[index]);
      },
    );
  }
}