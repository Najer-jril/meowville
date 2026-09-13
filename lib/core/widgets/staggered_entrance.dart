import 'package:flutter/widgets.dart';

class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  static const Duration _stepDelay = Duration(milliseconds: 70);
  static const Duration _itemDuration = Duration(milliseconds: 480);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _itemDuration + _stepDelay * (widget.children.length - 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int total = _controller.duration!.inMilliseconds;

    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < widget.children.length; i++)
          _item(i, total, widget.children[i]),
      ],
    );
  }

  Widget _item(int index, int total, Widget child) {
    final double start = (_stepDelay.inMilliseconds * index) / total;
    final double end = start + _itemDuration.inMilliseconds / total;
    final Animation<double> curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end.clamp(0, 1), curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}
