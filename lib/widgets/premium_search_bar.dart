/*
  Clean premium search bar implementation (replaced corrupted contents).
  This file provides a compact/dark variant, green search icon, mic support, and
  a clear button. It was rewritten to fix duplicated/malformed content that
  caused analysis errors.
*/


import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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

    // Use theme-aware decoration for both variants — supports dark mode
    final bgDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(isDark ? 12 : 14),
      color: isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).cardColor,
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
              // removed backdrop blur/shadow for a flat placeholder appearance
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
                        color: AppColors.primary,
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
                          color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: isDark ? 14 : 15,
                        color: theme.textTheme.bodyLarge?.color,
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
                            icon: Icon(Icons.close, color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Colors.grey),
                            onPressed: () {
                              widget.controller.clear();
                              widget.onChanged('');
                              _focusNode.requestFocus();
                            },
                          ),
                        IconButton(
                          tooltip: 'Voice',
                          icon: Icon(Icons.mic, color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Colors.grey),
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


