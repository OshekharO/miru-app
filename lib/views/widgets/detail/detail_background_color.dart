import 'package:fluent_ui/fluent_ui.dart';

class DetailBackgroundColor extends StatefulWidget {
  const DetailBackgroundColor({
    super.key,
    required this.controller,
  });
  final ScrollController controller;

  @override
  State<DetailBackgroundColor> createState() => _DetailBackgroundColorState();
}

class _DetailBackgroundColorState extends State<DetailBackgroundColor> {
  double scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      scrollOffset = widget.controller.offset;
      if (scrollOffset >= 255) {
        scrollOffset = 255;
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            FluentTheme.of(context).micaBackgroundColor.withOpacity(
                  scrollOffset / 255,
                ),
            FluentTheme.of(context).micaBackgroundColor,
          ],
        ),
      ),
    );
  }
}
