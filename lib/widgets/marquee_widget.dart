// lib/widgets/marquee_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';

class MarqueeWidget extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Duration backDuration;
  final Duration pauseDuration;

  const MarqueeWidget({
    Key? key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 6000), // מהירות גלילה
    this.backDuration = const Duration(milliseconds: 1), // חזרה מיידית
    this.pauseDuration = const Duration(milliseconds: 100), // השהייה קצרה
  }) : super(key: key);

  @override
  _MarqueeWidgetState createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    if (!mounted) return;
    
    // אם התוכן קצר מהמסך, אין צורך לגלול
    if (_scrollController.hasClients && 
        _scrollController.position.maxScrollExtent <= 0) {
      return;
    }

    _scroll();
  }

  void _scroll() async {
    if (!mounted || !_scrollController.hasClients) return;

    // גלילה לסוף
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: widget.animationDuration,
      curve: Curves.linear,
    );
    
    if (!mounted) return;
    await Future.delayed(widget.pauseDuration);
    
    if (!mounted) return;
    // חזרה להתחלה (קפיצה)
    _scrollController.jumpTo(0.0);
    
    if (!mounted) return;
    await Future.delayed(widget.pauseDuration);
    
    // חזרה על הפעולה
    _scroll();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: widget.child,
    );
  }
}