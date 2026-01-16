/*
  Clean premium search bar implementation (replaced corrupted contents).
  This file provides a compact/dark variant, green search icon, mic support, and
  a clear button. It was rewritten to fix duplicated/malformed content that
  caused analysis errors.
*/

import 'dart:ui';

import 'package:flutter/material.dart';

enum SearchBarVariant { standard, darkCompact }

class PremiumSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onMicTap;
  final String hintText;
  final SearchBarVariant variant;

  const PremiumSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onMicTap,
    this.hintText = 'Search stays, locations...',
    this.variant = SearchBarVariant.standard,
  });

  @override
  State<PremiumSearchBar> createState() => _PremiumSearchBarState();
}

class _PremiumSearchBarState extends State<PremiumSearchBar>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() => setState(() {});

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasText = widget.controller.text.isNotEmpty;
    final bool isDark = widget.variant == SearchBarVariant.darkCompact;

    final bgDecoration = isDark
        ? BoxDecoration(
            color: const Color(0xFF122E18),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.14),
                blurRadius: 10,
                offset: const Offset(0, 6),
              )
            ],
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isDark ? 6 : 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: isDark ? 48 : 56,
        decoration: bgDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isDark ? 12 : 14),
          child: Stack(
            children: [
              if (!isDark)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                  child: Container(color: Colors.transparent),
                ),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: isDark ? 12 : 10, right: isDark ? 8 : 6),
                    child: ScaleTransition(
                      scale: Tween(begin: 0.98, end: 1.0).animate(
                        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
                      ),
                      child: Icon(
                        Icons.search,
                        color: const Color(0xFF1B5E20),
                        size: isDark ? 20 : 22,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      onChanged: widget.onChanged,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: isDark ? 14 : 15,
                        color: isDark ? Colors.white : null,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: widget.onChanged,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Row(
                      children: [
                        if (hasText)
                          IconButton(
                            tooltip: 'Clear',
                            icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.grey),
                            onPressed: () {
                              widget.controller.clear();
                              widget.onChanged('');
                              _focusNode.requestFocus();
                            },
                          ),
                        IconButton(
                          tooltip: 'Voice',
                          icon: Icon(Icons.mic, color: isDark ? Colors.white70 : Colors.grey),
                          onPressed: widget.onMicTap,
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


