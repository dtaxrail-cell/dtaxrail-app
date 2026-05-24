import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class MyReturnsScreen extends StatefulWidget {
  const MyReturnsScreen({super.key});

  @override
  State<MyReturnsScreen> createState() => _MyReturnsScreenState();
}

class _MyReturnsScreenState extends State<MyReturnsScreen> {
  String _filter = 'All';

  static const List<Map<String, String>> _filings = [
    {
      'id': '#DTR-2025-001',
      'year': 'FY 2024-25',
      'type': 'ITR-1',
      'status': 'In Review',
      'date': '12 May 2025',
      'title': 'ITR Filing FY 2024-25',
    },
    {
      'id': '#DTR-2025-002',
      'year': 'FY 2024-25',
      'type': 'ITR-1',
      'status': 'Pending',
      'date': '01 Jun 2025',
      'title': 'Tax Notice Response',
    },
    {
      'id': '#DTR-2024-003',
      'year': 'FY 2023-24',
      'type': 'ITR-1',
      'status': 'Completed',
      'date': '18 Jul 2024',
      'title': 'ITR Filing FY 2023-24',
    },
    {
      'id': '#DTR-2023-007',
      'year': 'FY 2022-23',
      'type': 'ITR-2',
      'status': 'Completed',
      'date': '28 Jun 2023',
      'title': 'ITR Filing FY 2022-23',
    },
  ];

  static const _filters = ['All', 'Pending', 'In Review', 'Filed', 'Completed'];

  List<Map<String, String>> get _filtered {
    if (_filter == 'All') return List<Map<String, String>>.from(_filings);
    return _filings.where((o) => o['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Returns & Orders'),
        leading: BackButton(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Filter chips ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((s) {
                    final active = _filter == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                              active ? Colors.white : AppColors.textMid,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Filing cards list ─────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 60, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text(
                      'No filings found',
                      style: TextStyle(
                          color: AppColors.textLight,
                          fontFamily: 'Poppins',
                          fontSize: 14),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) =>
                    _FilingCard(filing: _filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filing Card ───────────────────────────────────────────────────────────
class _FilingCard extends StatelessWidget {
  final Map<String, String> filing;
  const _FilingCard({required this.filing});

  @override
  Widget build(BuildContext context) {
    final status = filing['status'] ?? 'Pending';
    final isCompleted = status == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  filing['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              StatusBadge(status),
            ],
          ),

          const SizedBox(height: 6),

          // ── Meta ─────────────────────────────────────────────────────
          Text(
            '${filing['year']} · ${filing['type']}',
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMid,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            'Order ID: ${filing['id']}  ·  Submitted: ${filing['date']}',
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
                fontFamily: 'Poppins'),
          ),

          const SizedBox(height: 14),

          // ── Progress bar (non-completed) ─────────────────────────────
          if (!isCompleted) ...[
            _MiniProgressBar(status: status),
            const SizedBox(height: 14),
          ],

          // ── Actions ──────────────────────────────────────────────────
          Row(
            children: [
              // Upload Docs button — disabled if Completed
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isCompleted
                      ? null
                      : () => _showUploadSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.divider,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.textLight,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: const Text(
                    'Upload Docs',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Download — only meaningful for Completed
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCompleted ? () {} : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: BorderSide(
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                    foregroundColor: isCompleted
                        ? AppColors.primary
                        : AppColors.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.download_rounded,
                    size: 16,
                    color: isCompleted
                        ? AppColors.primary
                        : AppColors.textLight,
                  ),
                  label: Text(
                    'Download',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.textLight,
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

  void _showUploadSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Documents',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Order ${filing['id']} — ${filing['title']}',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 20),
            _SheetOption(
              icon: Icons.file_upload_outlined,
              label: 'Browse Files',
              onTap: () => Navigator.pop(sheetCtx),
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take Photo / Scan',
              onTap: () => Navigator.pop(sheetCtx),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Mini Progress Bar ──────────────────────────────────────────────────────
class _MiniProgressBar extends StatelessWidget {
  final String status;
  const _MiniProgressBar({required this.status});

  int get _step {
    switch (status) {
      case 'Pending':
        return 0;
      case 'In Review':
        return 1;
      case 'Filed':
        return 2;
      case 'Completed':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = ['Received', 'Review', 'Filing', 'Done'];
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= _step;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: done ? AppColors.primary : AppColors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 8.5,
                        color: done ? AppColors.primary : AppColors.textLight,
                        fontFamily: 'Poppins',
                        fontWeight:
                        done ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1) const SizedBox(width: 3),
            ],
          ),
        );
      }),
    );
  }
}

// ── Upload Sheet Option ────────────────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}