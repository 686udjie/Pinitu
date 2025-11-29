import 'package:flutter/material.dart';

class DownloadNotification extends StatefulWidget {
  final ValueNotifier<String> messageNotifier;
  final ValueNotifier<IconData> iconNotifier;
  final Duration duration;

  const DownloadNotification({
    super.key,
    required this.messageNotifier,
    required this.iconNotifier,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<DownloadNotification> createState() => _DownloadNotificationState();
}

class _DownloadNotificationState extends State<DownloadNotification>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
    widget.messageNotifier.addListener(_onMessageChanged);
    widget.iconNotifier.addListener(_onIconChanged);
    Future.delayed(widget.duration, () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    widget.messageNotifier.removeListener(_onMessageChanged);
    widget.iconNotifier.removeListener(_onIconChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onMessageChanged() {
    setState(() {});
  }

  void _onIconChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Align(
        alignment: Alignment(0, 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.iconNotifier.value,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                widget.messageNotifier.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
