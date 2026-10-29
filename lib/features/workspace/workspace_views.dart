import 'package:flutter/material.dart';

/// Stable slots retain native views and document widgets through tab/layout changes.
class WorkspaceViews extends StatelessWidget {
  const WorkspaceViews({
    super.key,
    required this.code,
    required this.preview,
    required this.showPreview,
    required this.hasPreview,
  });

  final Widget code;
  final Widget preview;
  final bool showPreview;
  final bool hasPreview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, size) {
        final split = hasPreview && size.maxWidth >= 840;
        final width = split ? size.maxWidth / 2 : size.maxWidth;
        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: width,
              child: ExcludeFocus(
                excluding: !split && showPreview,
                child: Offstage(offstage: !split && showPreview, child: code),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: width,
              child: ExcludeFocus(
                excluding: !split && !showPreview,
                child: Offstage(
                  offstage: !split && !showPreview,
                  child: preview,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
