import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 底栏各 Tab 横向滑动容器（PageView + go_router StatefulNavigationShell）
class ShellPageContainer extends StatefulWidget {
  const ShellPageContainer({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<ShellPageContainer> createState() => _ShellPageContainerState();
}

class _ShellPageContainerState extends State<ShellPageContainer> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(ShellPageContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.navigationShell.currentIndex;
    if (index == oldWidget.navigationShell.currentIndex) return;
    if (!_pageController.hasClients) return;
    final current = _pageController.page?.round();
    if (current == index) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index == widget.navigationShell.currentIndex) return;
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: widget.children,
    );
  }
}
