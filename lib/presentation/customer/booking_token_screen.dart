import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_client.dart';
import '../../core/services/user_service.dart';
import '../../theme/app_theme.dart';

class BookingTokenScreen extends StatefulWidget {
  final String bookingId;
  final String confirmationToken;
  final String venueName;
  final String eventDate;

  const BookingTokenScreen({
    super.key,
    required this.bookingId,
    required this.confirmationToken,
    required this.venueName,
    required this.eventDate,
  });

  @override
  State<BookingTokenScreen> createState() => _BookingTokenScreenState();
}

class _BookingTokenScreenState extends State<BookingTokenScreen> {
  bool _isDownloading = false;
  double _progress = 0;
  String? _savedPath;
  String? _errorMsg;

  static const _platform = MethodChannel('com.example.venuelink/pdf');

  Future<void> _downloadToken() async {
    setState(() {
      _isDownloading = true;
      _progress = 0;
      _errorMsg = null;
    });

    try {
      final authToken = await UserService.getAuthToken();
      if (authToken == null) throw Exception('Not authenticated');

      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final filename = 'VenueMate_Token_${widget.confirmationToken}.pdf';
      final savePath = '${downloadsDir.path}/$filename';

      final dio = Dio();
      await dio.download(
        '${ApiClient.baseUrl}/bookings/${widget.bookingId}/token-pdf',
        savePath,
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) setState(() => _progress = received / total);
        },
      );

      setState(() {
        _savedPath = savePath;
        _isDownloading = false;
        _progress = 1;
      });

      try {
        await _openPdf(savePath);
      } catch (_) {
        // PDF saved fine, open failed silently
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMsg = 'Download failed. Please try again.';
      });
    }
  }

  Future<void> _openPdf(String path) async {
    try {
      // Use FileProvider via platform channel to avoid FileUriExposedException
      await _platform.invokeMethod('openPdf', {'path': path});
    } catch (e) {
      // Fallback snackbar if native open fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF saved as VenueMate_Token_${widget.confirmationToken}.pdf — open it from your Downloads folder.',
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Booking Token'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Confirmed banner ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.successContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_rounded,
                        color: AppTheme.success, size: 34),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Booking Confirmed!',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your advance payment has been received.\nYour slot is now reserved.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.onSurfaceMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Token number ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary, width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    'TOKEN NUMBER',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceMuted,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.confirmationToken,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Quick summary ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _summaryRow(context, Icons.store_rounded,
                      'Venue', widget.venueName),
                  const Divider(height: 20, color: AppTheme.outlineVariant),
                  _summaryRow(context, Icons.calendar_today_rounded,
                      'Event Date', widget.eventDate),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Download / progress ────────────────────────────────────────
            if (_isDownloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  backgroundColor: AppTheme.outlineVariant,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _progress == 0
                    ? 'Preparing your token...'
                    : 'Downloading... ${(_progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceMuted),
                textAlign: TextAlign.center,
              ),
            ] else if (_savedPath != null) ...[
              ElevatedButton.icon(
                onPressed: () => _openPdf(_savedPath!),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Open Token PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _downloadToken,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Again'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _downloadToken,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Booking Token PDF'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],

            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Info note ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.onSurfaceMuted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your token PDF is saved in your Downloads folder. '
                      'Present it at the venue on your event day.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppTheme.onSurfaceMuted),
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
