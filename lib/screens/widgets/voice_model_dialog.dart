// lib/screens/widgets/voice_model_dialog.dart
import 'package:flutter/material.dart';
import 'package:fukatsongs/core/theme/app_theme.dart';
import 'package:fukatsongs/services/voice_model_downloader.dart';
import 'package:fukatsongs/services/vosk_voice_service.dart';

/// Shows the one-time hands-free model download **and** the list of every
/// voice command the app understands.
///
/// The command list is read from [VoskVoiceService.grammarGroups], i.e. from
/// the same `_grammar` array that is handed to Vosk — there is no second copy
/// to keep in sync.
///
/// Returns `true` when the model is ready on disk (downloaded now or already
/// present), `false` if the user cancelled or it failed.
Future<bool> showVoiceModelDownloadDialog(
  BuildContext context, {
  String title = 'Hands-free voice setup',
}) async {
  final downloader = VoiceModelDownloader.instance;

  if (await downloader.isReady()) {
    // Model already there → this is just the "what can I say?" box.
    if (!context.mounted) return true;
    await showDialog<bool>(
      context: context,
      builder: (_) => _VoiceModelDialog(title: 'Voice commands', onlyInfo: true),
    );
    return true;
  }
  if (!context.mounted) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _VoiceModelDialog(title: title),
  );
  return result ?? false;
}

class _VoiceModelDialog extends StatefulWidget {
  const _VoiceModelDialog({required this.title, this.onlyInfo = false});

  final String title;

  /// True when the model is already downloaded: show commands only, no bar.
  final bool onlyInfo;

  @override
  State<_VoiceModelDialog> createState() => _VoiceModelDialogState();
}

class _VoiceModelDialogState extends State<_VoiceModelDialog> {
  final _downloader = VoiceModelDownloader.instance;

  @override
  void initState() {
    super.initState();
    if (widget.onlyInfo) return;
    // Kick off here (not in the caller) so the dialog owns the whole
    // lifecycle and can cancel the HTTP request if it is dismissed.
    _downloader.ensureModel().then((path) {
      if (!mounted) return;
      // On success close immediately. On failure stay open — the user needs
      // to read the reason ("No internet connection.", HTTP 404, …) and can
      // then press Close themselves.
      if (path != null) Navigator.of(context).pop(true);
    });
  }

  @override
  void dispose() {
    // If the dialog goes away while still downloading (back button / route
    // pop), abort the request instead of leaking it.
    if (_downloader.isDownloading.value) _downloader.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Default_Theme.themeColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.mic, color: Default_Theme.accentColor2, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        // scrollable: the command list can be taller than a short screen.
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.onlyInfo) ...[
                ValueListenableBuilder<VoiceModelProgress>(
                  valueListenable: _downloader.progress,
                  builder: (context, p, _) => _ProgressBlock(progress: p),
                ),
                const SizedBox(height: 20),
                Divider(
                  height: 1,
                  color: Default_Theme.primaryColor1.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 16),
              ],
              const _CommandList(),
            ],
          ),
        ),
        actions: [
          if (widget.onlyInfo)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            )
          else
            ValueListenableBuilder<bool>(
              valueListenable: _downloader.isDownloading,
              builder: (context, busy, _) => TextButton(
                onPressed: () {
                  if (busy) _downloader.cancel();
                  Navigator.of(context).pop(false);
                },
                child: Text(busy ? 'Cancel' : 'Close'),
              ),
            ),
        ],
      ),
    );
  }
}

/// The progress bar + "12.3 MB / 39.3 MB · 31%" + speed / ETA row.
class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.progress});
  final VoiceModelProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final failed = p.phase == VoiceModelPhase.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          failed
              ? 'Download failed'
              : 'Downloading the offline voice model (one-time, ~39 MB).',
          style: TextStyle(
            fontSize: 13,
            color: failed
                ? Colors.redAccent
                : Default_Theme.primaryColor1.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 18),

        // ── Progress bar ────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            // null = indeterminate spinner (connecting / extracting)
            value: (p.phase == VoiceModelPhase.downloading && p.total > 0)
                ? p.fraction
                : null,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              failed ? Colors.redAccent : Default_Theme.accentColor2,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Bytes / percent / speed / eta ───────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              p.phase == VoiceModelPhase.downloading && p.total > 0
                  ? '${p.text}  ·  ${(p.fraction * 100).toStringAsFixed(0)}%'
                  : (p.message.isNotEmpty ? p.message : 'Starting…'),
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
            if (p.phase == VoiceModelPhase.downloading && p.bytesPerSecond > 1)
              Text(
                (p.etaSeconds != null && p.etaSeconds! > 0)
                    ? '${p.speedText}  ·  ${p.etaSeconds}s left'
                    : p.speedText,
                style: TextStyle(
                  fontSize: 12,
                  color: Default_Theme.primaryColor1.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),

        if (failed && p.message.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(p.message,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
        ],
      ],
    );
  }
}

/// Every phrase the recogniser accepts, grouped. Read-only — the data comes
/// from [VoskVoiceService.grammarGroups], i.e. the real Vosk grammar.
class _CommandList extends StatelessWidget {
  const _CommandList();

  @override
  Widget build(BuildContext context) {
    final groups = VoskVoiceService.grammarGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.record_voice_over,
                size: 15, color: Default_Theme.accentColor2),
            const SizedBox(width: 6),
            Text(
              'Voice commands',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Default_Theme.primaryColor1.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Say any phrase exactly — check setting to view commands',
          style: TextStyle(
            fontSize: 11,
            color: Default_Theme.primaryColor1.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        ...groups.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.key,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Default_Theme.accentColor2
                        .withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: e.value
                      .map(
                        (phrase) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          child: Text(
                            '"$phrase"',
                            style: TextStyle(
                              fontSize: 11.5,
                              color:
                                  Default_Theme.primaryColor1.withValues(
                                      alpha: 0.85),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
