import 'package:flutter/material.dart';

class RiseIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const RiseIn({super.key, 
    required this.child,
    // ignore: unused_element_parameter
    this.delay = Duration.zero,
  });

  @override
  State<RiseIn> createState() => RiseInState();
}

class RiseInState extends State<RiseIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _rise;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _rise = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _rise,
        child: widget.child,
      ),
    );
  }
}

