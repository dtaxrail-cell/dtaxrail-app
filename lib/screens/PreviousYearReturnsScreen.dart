import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/filing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

// ─── Helper: determine current assessment year ────────────────────────────────
// AY format in data: "2024-25", "2025-26", etc.
// Indian FY starts April 1. AY = FY + 1.
// e.g. today June 2026 → FY 2026-27 → current AY = "2026-27"
String _currentAssessmentYear() {
  final now = DateTime.now();
  final fyStart = now.month >= 4 ? now.year : now.year - 1;
  final ayStart = fyStart + 1;
  final ayEnd   = (ayStart + 1) % 100; // last two digits
  return '$ayStart-${ayEnd.toString().padLeft(2, '0')}';
}

// Returns true if [ay] is strictly before [currentAY]
// Compares the 4-digit start year (before the dash)
bool _isBeforeCurrentAY(String? ay) {
  if (ay == null || ay.isEmpty) return false;
  final currentStart = int.tryParse(_currentAssessmentYear().split('-').first) ?? 9999;
  final itemStart    = int.tryParse(ay.split('-').first) ?? 9999;
  return itemStart < currentStart;
}

class PreviousYearReturnsScreen extends StatefulWidget {
  const PreviousYearReturnsScreen({super.key});

  @override
  State<PreviousYearReturnsScreen> createState() =>
      _PreviousYearReturnsScreenState();
}

class _PreviousYearReturnsScreenState
    extends State<PreviousYearReturnsScreen> {

  bool          _isLoading = true;
  List<dynamic> _filings   = [];

  @override
  void initState() {
    super.initState();
    _loadFilings();
  }

  Future<void> _loadFilings() async {
    setState(() => _isLoading = true);

    final all = await FilingService.getCustomerFilings();

    if (!mounted) return;

    // Filter: Completed + assessment_year is before current AY
    final previous = all.where((f) {
      final isCompleted = (f['status'] ?? '') == 'Completed';
      final isPastAY    = _isBeforeCurrentAY(f['assessment_year']?.toString());
      return isCompleted && isPastAY;
    }).toList();

    setState(() {
      _filings   = previous;
      _isLoading = false;
    });
  }

  Future<void> _openFile(String url) async {
    try {
      final uri      = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open file")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: const Text(
          'Previous Year Returns',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filings.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
        onRefresh: _loadFilings,
        child: ListView.builder(
          padding:    const EdgeInsets.all(18),
          itemCount:  _filings.length,
          itemBuilder: (ctx, i) =>
              _PreviousYearCard(filing: _filings[i], onOpenFile: _openFile),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history_rounded, size: 64, color: AppColors.textLight),
          SizedBox(height: 14),
          Text(
            'No previous year returns found',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textLight,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Completed filings from past years\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────
class _PreviousYearCard extends StatelessWidget {
  final dynamic                    filing;
  final Future<void> Function(String) onOpenFile;

  const _PreviousYearCard({
    required this.filing,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    final status   = filing['status']           ?? 'Completed';
    final isPaid   = filing['payment_status']   == 'Paid';
    final fileUrl  = filing['file_url']?.toString()  ?? '';
    final fileName = filing['file_name']?.toString()  ?? 'Result File';
    final hasFile  = fileUrl.isNotEmpty;

    return Container(
      margin:     const EdgeInsets.only(bottom: 16),
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  filing['filing_type'] ?? 'ITR Filing',
                  style: const TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.textDark,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              StatusBadge(status),
            ],
          ),

          const SizedBox(height: 10),

          // ── Member ─────────────────────────────────────────────────────────
          Text(
            filing['member_name'] ?? 'Family Member',
            style: const TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      AppColors.textMid,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Relationship: ${filing['relationship'] ?? "Self"}',
            style: const TextStyle(
              fontSize:   11,
              color:      AppColors.textLight,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Assessment Year: ${filing['assessment_year'] ?? "—"}',
            style: const TextStyle(
              fontSize:   11,
              color:      AppColors.textLight,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Documents Uploaded: ${filing['document_count'] ?? 0}',
            style: const TextStyle(
              fontSize:   11,
              color:      AppColors.textLight,
              fontFamily: 'Poppins',
            ),
          ),

          // ── Payment status ─────────────────────────────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isPaid ? Icons.verified_rounded : Icons.cancel_rounded,
                color: isPaid ? Colors.green : Colors.red,
                size:  18,
              ),
              const SizedBox(width: 6),
              Text(
                isPaid ? 'Payment Completed' : 'Payment Pending',
                style: TextStyle(
                  color:      isPaid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize:   12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),

          // ── Result file (if present) ───────────────────────────────────────
          if (hasFile) ...[
            const SizedBox(height: 14),
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => onOpenFile(fileUrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation:       0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon:  const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text(
                      'Open',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── View Filing button (read-only — NO Add Docs) ───────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showFilingDetails(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:         const EdgeInsets.symmetric(vertical: 12),
                elevation:       0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon:  const Icon(Icons.visibility_rounded, size: 16),
              label: const Text(
                'View Details',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilingDetails(BuildContext context) {
    final isPaid = filing['payment_status'] == 'Paid';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          filing['filing_type'] ?? 'ITR Filing',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize:      MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member: ${filing['member_name'] ?? "—"}'),
            const SizedBox(height: 8),
            Text('Status: ${filing['status'] ?? "—"}'),
            const SizedBox(height: 8),
            Text('Assessment Year: ${filing['assessment_year'] ?? "—"}'),
            const SizedBox(height: 8),
            Text('Relationship: ${filing['relationship'] ?? "Self"}'),
            const SizedBox(height: 8),
            Text('Documents: ${filing['document_count'] ?? 0}'),
            const SizedBox(height: 8),
            Text('Payment: ${filing['payment_status'] ?? "Pending"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}