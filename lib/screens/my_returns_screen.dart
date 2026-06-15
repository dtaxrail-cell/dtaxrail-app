import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

import '../services/filing_service.dart';
import '../services/document_service.dart';

// ─── Same AY helper (keep in sync with previous_year_returns_screen.dart) ─────
String _currentAssessmentYear() {
  final now     = DateTime.now();
  final fyStart = now.month >= 4 ? now.year : now.year - 1;
  final ayStart = fyStart + 1;
  final ayEnd   = (ayStart + 1) % 100;
  return '$ayStart-${ayEnd.toString().padLeft(2, '0')}';
}

bool _isPreviousYearFiling(dynamic f) {
  final isCompleted  = (f['status'] ?? '') == 'Completed';
  final ay           = f['assessment_year']?.toString() ?? '';
  if (!isCompleted || ay.isEmpty) return false;
  final currentStart = int.tryParse(_currentAssessmentYear().split('-').first) ?? 9999;
  final itemStart    = int.tryParse(ay.split('-').first) ?? 9999;
  return itemStart < currentStart;
}

class MyReturnsScreen extends StatefulWidget {
  const MyReturnsScreen({super.key});

  @override
  State<MyReturnsScreen> createState() => _MyReturnsScreenState();
}

class _MyReturnsScreenState extends State<MyReturnsScreen> {
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

    // Exclude filings that belong in Previous Year Returns
    final active = all.where((f) => !_isPreviousYearFiling(f)).toList();

    setState(() {
      _filings   = active;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Returns & Orders'),
        leading: const BackButton(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filings.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 60, color: AppColors.textLight),
              SizedBox(height: 12),
              Text(
                'No active filings found',
                style: TextStyle(
                  color:      AppColors.textLight,
                  fontFamily: 'Poppins',
                  fontSize:   14,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Completed past-year filings are in\nPrevious Year Returns.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:      AppColors.textLight,
                  fontFamily: 'Poppins',
                  fontSize:   12,
                ),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadFilings,
          child: ListView.builder(
            padding:    const EdgeInsets.all(18),
            itemCount:  _filings.length,
            itemBuilder: (ctx, i) => _FilingCard(filing: _filings[i]),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// FILING CARD
// ==========================================
class _FilingCard extends StatelessWidget {
  final dynamic filing;

  const _FilingCard({required this.filing});

  @override
  Widget build(BuildContext context) {
    final status = filing['status'] ?? 'Pending';

    final bool hasRequest =
        filing['latest_admin_message'] != null &&
            filing['latest_admin_message'].toString().trim().isNotEmpty &&
            status == 'Documents Requested';

    final bool isCompleted = status == 'Completed';
    final bool isPaid      = filing['payment_status'] == 'Paid';

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

          // ── Header ────────────────────────────────────────────────────────
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

          // ── Member ────────────────────────────────────────────────────────
          Text(
            filing['member_name'] ?? 'Family Member',
            style: const TextStyle(
              fontSize:   13,
              color:      AppColors.textMid,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Relationship: ${filing['relationship'] ?? "Self"}',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontFamily: 'Poppins'),
          ),

          const SizedBox(height: 4),

          Text(
            'Documents Uploaded: ${filing['document_count'] ?? 0}',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontFamily: 'Poppins'),
          ),

          // ── Payment status ────────────────────────────────────────────────
          if (isCompleted) ...[
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
          ],

          // ── Admin request banner ──────────────────────────────────────────
          if (hasRequest) ...[
            const SizedBox(height: 14),
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: Colors.orange.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Additional Documents Requested',
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color:      Colors.orange,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filing['latest_admin_message'] ?? '',
                    style: const TextStyle(
                      fontSize:   12,
                      color:      AppColors.textDark,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Buttons ───────────────────────────────────────────────────────
          Row(
            children: [

              // VIEW
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showFilingDetails(context, filing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:         const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon:  const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text(
                    'View Filing',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ADD DOCS — always enabled
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showUploadDialog(context, filing),
                  style: OutlinedButton.styleFrom(
                    padding:         const EdgeInsets.symmetric(vertical: 11),
                    side:            const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon:  const Icon(Icons.upload_file_rounded, size: 16, color: AppColors.primary),
                  label: const Text(
                    'Add Docs',
                    style: TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                      fontSize: 13, color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── View Details ────────────────────────────────────────────────────────────
  void _showFilingDetails(BuildContext context, dynamic filing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(filing['filing_type'] ?? 'ITR Filing'),
        content: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member: ${filing['member_name']}'),
            const SizedBox(height: 8),
            Text('Status: ${filing['status']}'),
            const SizedBox(height: 8),
            Text('Documents: ${filing['document_count']}'),
            const SizedBox(height: 8),
            Text('Payment: ${filing['payment_status'] ?? "Pending"}'),
            if (filing['latest_admin_message'] != null) ...[
              const SizedBox(height: 14),
              const Text('Admin Request:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(filing['latest_admin_message']),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  // ── Upload Dialog ───────────────────────────────────────────────────────────
  void _showUploadDialog(BuildContext context, dynamic filing) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Additional Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),
            Text(
              filing['latest_admin_message'] != null &&
                  filing['latest_admin_message'].toString().trim().isNotEmpty
                  ? filing['latest_admin_message']
                  : 'Upload any additional supporting documents for this filing.',
            ),
            const SizedBox(height: 24),

            // FILE PICKER
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await DocumentService.pickAndUploadDocument(
                    filingId:     filing['id'],
                    documentType: "Additional Document",
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? "Document uploaded successfully" : "Upload cancelled"),
                  ));
                },
                icon:  const Icon(Icons.upload_file_rounded),
                label: const Text('Upload From Files'),
              ),
            ),

            const SizedBox(height: 14),

            // CAMERA
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final success = await DocumentService.captureAndUploadDocument(
                    filingId:     filing['id'],
                    documentType: "Additional Document",
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? "Document scanned and uploaded" : "Camera upload cancelled"),
                  ));
                },
                icon:  const Icon(Icons.camera_alt_rounded),
                label: const Text('Scan Using Camera'),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}