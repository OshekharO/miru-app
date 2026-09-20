import 'package:flutter/material.dart';

class DetailAppbarTitle extends StatefulWidget {
  const DetailAppbarTitle(
    this.text, {
    super.key,
    required this.controller,
  });
  final String text;
  final ScrollController controller;

  @override
  State<DetailAppbarTitle> createState() => _DetailAppbarTitleState();
}

class _DetailAppbarTitleState extends State<DetailAppbarTitle> {
  double _offset = 0;

  void _onScroll() {
    if (mounted) {
      setState(() {
        _offset = widget.controller.offset;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  double _scrollListener() {
    if (_offset <= 300) {
      return 0;
    } else {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text,
      style: TextStyle(
        color: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color!
            .withOpacity(_scrollListener()),
      ),
    );
  }
}
