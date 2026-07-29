import 'dart:typed_data';
// dartz also exports a `State` type, which would shadow Flutter's.
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import '../error/failures.dart';
import '../theme/app_colors.dart';
import '../utils/file_download/file_download.dart';

/// Outlined "Export" button for a single record's detail page — used by the
/// Lead / Account / Contact / Deal detail screens, which each export via
/// `to_export=true` on their GET-by-id route.
///
/// [fetch] returns the xlsx bytes; the button owns the in-flight spinner, the
/// browser/mobile download, and the success/failure snackbars so each detail
/// page doesn't repeat that plumbing.
class RecordExportButton extends StatefulWidget {
  const RecordExportButton({
    super.key,
    required this.fetch,
    required this.fileName,
    this.successMessage,
    this.iconOnly = false,
    this.tooltip = 'Export to Excel',
  });

  final Future<Either<Failure, Uint8List>> Function() fetch;

  /// Saved-as name, e.g. `lead_101.xlsx`.
  final String fileName;

  /// Snackbar text on success. Defaults to `Exported <fileName>.`
  final String? successMessage;

  /// Render as a bare icon button — for headers that are tight on space.
  final bool iconOnly;
  final String tooltip;

  @override
  State<RecordExportButton> createState() => _RecordExportButtonState();
}

class _RecordExportButtonState extends State<RecordExportButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    final result = await widget.fetch();
    if (!mounted) return;
    setState(() => _busy = false);

    await result.fold(
      (f) async => messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (bytes) async {
        await downloadBytes(bytes, widget.fileName);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.successMessage ?? 'Exported ${widget.fileName}.',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final spinner = const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    if (widget.iconOnly) {
      return IconButton(
        tooltip: widget.tooltip,
        onPressed: _busy ? null : _run,
        icon: _busy
            ? spinner
            : const Icon(Icons.file_download_outlined, size: 18),
      );
    }

    return OutlinedButton.icon(
      onPressed: _busy ? null : _run,
      icon: _busy
          ? spinner
          : const Icon(Icons.file_download_outlined, size: 16),
      label: Text(_busy ? 'Exporting...' : 'Export'),
    );
  }
}
