import 'package:flutter/material.dart';

import '../../core/theme/app_styles.dart';
import '../../core/theme/app_theme.dart';
import 'order_swipe_group.dart';
import 'order_swipe_scope.dart';

/// 左滑订单卡片，露出右侧「打印 / 取消」；右滑可收回。
class OrderSwipeActions extends StatefulWidget {
  const OrderSwipeActions({
    super.key,
    required this.child,
    this.group,
    this.onPrint,
    this.printing = false,
    this.onRemove,
    this.removing = false,
    this.removeLabel = '取消',
  });

  final Widget child;
  final OrderSwipeGroup? group;
  final VoidCallback? onPrint;
  final bool printing;
  final VoidCallback? onRemove;
  final bool removing;
  final String removeLabel;

  @override
  State<OrderSwipeActions> createState() => _OrderSwipeActionsState();
}

class _OrderSwipeActionsState extends State<OrderSwipeActions>
    with SingleTickerProviderStateMixin {
  static const _actionWidth = 112.0;
  static const _openThreshold = 0.35;

  late AnimationController _controller;
  late Animation<double> _offsetAnim;

  bool get _hasActions => widget.onPrint != null || widget.onRemove != null;

  double get _offset => _offsetAnim.value;

  bool get _isOpen => _controller.value >= 0.99;

  OrderSwipeGroup? get _group =>
      widget.group ?? OrderSwipeScope.maybeOf(context);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _offsetAnim = Tween<double>(begin: 0, end: _actionWidth).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _group?.release(_closeSilently);
    _controller.dispose();
    super.dispose();
  }

  void _closeSilently() {
    if (!mounted) return;
    _controller.value = 0;
  }

  void _setOffset(double value) {
    _controller.value = (value / _actionWidth).clamp(0.0, 1.0);
  }

  Future<void> _snapTo(bool open) async {
    if (_controller.isAnimating) return;
    if (open) {
      _group?.open(_closeSilently);
      await _controller.forward();
    } else {
      await _controller.reverse();
      _group?.release(_closeSilently);
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_controller.isAnimating) return;
    if (_isOpen) _group?.open(_closeSilently);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) return;
    final next = (_offset - details.delta.dx).clamp(0.0, _actionWidth);
    _setOffset(next);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_controller.isAnimating) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 350) {
      _snapTo(false);
      return;
    }
    if (velocity < -350) {
      _snapTo(true);
      return;
    }
    _snapTo(_offset > _actionWidth * _openThreshold);
  }

  void _onHorizontalDragCancel() {
    _snapTo(_offset > _actionWidth * _openThreshold);
  }

  void _runAction(VoidCallback? action) {
    if (action == null) return;
    action();
    _snapTo(false);
  }

  Widget _buildActions({required bool interactive}) {
    return IgnorePointer(
      ignoring: !interactive,
      child: Row(
        children: [
          if (widget.onPrint != null)
            Expanded(
              child: _SwipeActionButton(
                icon: Icons.print_outlined,
                label: '打印',
                color: AppStyles.textPrimary,
                backgroundColor: AppStyles.surfaceMuted,
                loading: widget.printing,
                onTap: widget.printing
                    ? null
                    : () => _runAction(widget.onPrint),
              ),
            ),
          if (widget.onRemove != null)
            Expanded(
              child: _SwipeActionButton(
                icon: Icons.close_rounded,
                label: widget.removeLabel,
                color: AppColors.error,
                backgroundColor: AppColors.error.withValues(alpha: 0.12),
                loading: widget.removing,
                onTap: widget.removing
                    ? null
                    : () => _runAction(widget.onRemove),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasActions) return widget.child;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AnimatedBuilder(
        animation: _offsetAnim,
        builder: (context, child) {
          final showInteractiveActions = _offset > 0;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: _actionWidth,
                child: _buildActions(interactive: false),
              ),
              if (showInteractiveActions)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: _actionWidth,
                  child: _buildActions(interactive: true),
                ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onHorizontalDragStart,
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                onHorizontalDragCancel: _onHorizontalDragCancel,
                child: Transform.translate(
                  offset: Offset(-_offset, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: _offset > 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(-2, 0),
                              ),
                            ]
                          : null,
                    ),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: color),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
