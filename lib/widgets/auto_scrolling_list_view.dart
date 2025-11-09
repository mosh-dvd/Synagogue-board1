// lib/widgets/auto_scrolling_list_view.dart
// ******** תיקון טעות ההקלדה הקריטית כאן ********
import 'dart:async';
import 'package:flutter/material.dart';

class AutoScrollingListView extends StatefulWidget {
  final List<Widget> children;
  final Duration pauseDuration;
  final int scrollSpeed; // pixels per second

  const AutoScrollingListView({
    Key? key,
    required this.children,
    this.pauseDuration = const Duration(seconds: 4),
    this.scrollSpeed = 30,
  }) : super(key: key);

  @override
  _AutoScrollingListViewState createState() => _AutoScrollingListViewState();
}

class _AutoScrollingListViewState extends State<AutoScrollingListView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  bool _isScrollingForward = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOrUpdateAutoScroll();
    });
  }

  @override
  void didUpdateWidget(AutoScrollingListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         _isScrollingForward = true;
        _startOrUpdateAutoScroll();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startOrUpdateAutoScroll() {
    _timer?.cancel();
    // ודא שהבקר מחובר לווידג'ט לפני שמתחילים
    if (!mounted || !_scrollController.hasClients || _scrollController.position.maxScrollExtent <= 0) {
      return;
    }
    _timer = Timer(widget.pauseDuration, _performScrollCycle);
  }

  void _performScrollCycle() {
    if (!mounted || !_scrollController.hasClients || _scrollController.position.maxScrollExtent <= 0) {
      return;
    }

    final target = _isScrollingForward ? _scrollController.position.maxScrollExtent : 0.0;
    
    final distance = (_scrollController.position.maxScrollExtent - _scrollController.position.minScrollExtent);
    final scrollDurationMs = (distance * 1000 / widget.scrollSpeed).round();
    
    _scrollController.animateTo(
      target,
      duration: Duration(milliseconds: scrollDurationMs > 0 ? scrollDurationMs : 1),
      curve: Curves.linear,
    ).whenComplete(() {
      if (mounted) {
        _isScrollingForward = !_isScrollingForward;
        _timer = Timer(widget.pauseDuration, _performScrollCycle);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: widget.children,
    );
  }
}