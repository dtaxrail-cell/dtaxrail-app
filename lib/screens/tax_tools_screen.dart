import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TaxToolsScreen extends StatefulWidget {
  const TaxToolsScreen({super.key});

  @override
  State<TaxToolsScreen> createState() => _TaxToolsScreenState();
}

class _TaxToolsScreenState extends State<TaxToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _incomeCtrl = TextEditingController();
  final _deductionCtrl = TextEditingController();
  double _oldTax = 0, _newTax = 0;
  bool _calculated = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _incomeCtrl.dispose();
    _deductionCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final income = double.tryParse(_incomeCtrl.text.replaceAll(',', '')) ?? 0;
    final deductions =
        double.tryParse(_deductionCtrl.text.replaceAll(',', '')) ?? 0;
    setState(() {
      _oldTax = _calcOld(income, deductions);
      _newTax = _calcNew(income);
      _calculated = true;
    });
  }

  double _calcOld(double income, double deductions) {
    final taxable = (income - deductions).clamp(0.0, double.infinity);
    double tax = 0;
    if (taxable > 1000000) {
      tax += (taxable - 1000000) * 0.30;
      tax += 200000 * 0.20;
      tax += 250000 * 0.10;
    } else if (taxable > 750000) {
      tax += (taxable - 750000) * 0.20;
      tax += 250000 * 0.10;
    } else if (taxable > 500000) {
      tax += (taxable - 500000) * 0.10;
    }
    return tax * 1.04;
  }

  double _calcNew(double income) {
    double tax = 0;
    if (income > 1500000) {
      tax += (income - 1500000) * 0.30;
      tax += 300000 * 0.20;
      tax += 300000 * 0.15;
      tax += 300000 * 0.10;
      tax += 300000 * 0.05;
    } else if (income > 1200000) {
      tax += (income - 1200000) * 0.20;
      tax += 300000 * 0.15;
      tax += 300000 * 0.10;
      tax += 300000 * 0.05;
    } else if (income > 900000) {
      tax += (income - 900000) * 0.15;
      tax += 300000 * 0.10;
      tax += 300000 * 0.05;
    } else if (income > 600000) {
      tax += (income - 600000) * 0.10;
      tax += 300000 * 0.05;
    } else if (income > 300000) {
      tax += (income - 300000) * 0.05;
    }
    return tax * 1.04;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tax Tools'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12.5),
          tabs: const [
            Tab(text: '🧮 Calculator'),
            Tab(text: '📅 Deadlines'),
            Tab(text: '⚖️ Regime Compare'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCalculator(),
          _buildDeadlines(),
          _buildRegimeCompare(),
        ],
      ),
    );
  }

  Widget _buildCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Tax Calculator'),
          const SizedBox(height: 6),
          const Text('Estimate your tax liability for FY 2024-25',
              style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 24),
          TextFormField(
            controller: _incomeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Annual Income (₹)',
              hintText: 'e.g. 1200000',
              prefixIcon: Icon(Icons.currency_rupee_rounded,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _deductionCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Deductions under 80C, HRA etc. (₹)',
              hintText: 'e.g. 150000',
              prefixIcon: Icon(Icons.discount_outlined,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
              label: 'Calculate Tax',
              onTap: _calculate,
              icon: Icons.calculate_rounded),
          if (_calculated) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _TaxResultCard(
                    label: 'Old Regime',
                    amount: _oldTax,
                    highlight: _oldTax < _newTax,
                    highlightLabel: 'Better',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TaxResultCard(
                    label: 'New Regime',
                    amount: _newTax,
                    highlight: _newTax < _oldTax,
                    highlightLabel: 'Better',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InfoCard(
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _oldTax < _newTax
                          ? 'Old Regime saves you ₹${(_newTax - _oldTax).toStringAsFixed(0)} with your deductions.'
                          : 'New Regime saves you ₹${(_oldTax - _newTax).toStringAsFixed(0)}. Consider fewer deduction claims.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMid,
                          fontFamily: 'Poppins',
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeadlines() {
    // Using plain lists instead of record types
    final dates = [
      'July 31, 2025',
      'Oct 31, 2025',
      'Dec 31, 2025',
      'Mar 15, 2025',
      'Jun 15, 2025',
    ];
    final labels = [
      'ITR filing deadline (non-audit)',
      'ITR filing deadline (audit cases)',
      'Belated/revised return deadline',
      'Advance tax — 4th installment',
      'Advance tax — 1st installment FY26',
    ];
    final isPastList = [false, false, false, true, false];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      itemCount: dates.length,
      itemBuilder: (ctx, i) {
        final isPast = isPastList[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isPast ? AppColors.surface : AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isPast
                    ? AppColors.divider
                    : AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPast ? AppColors.divider : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.event_rounded,
                    color: isPast ? AppColors.textLight : AppColors.primary,
                    size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isPast ? AppColors.textLight : AppColors.textDark,
                          fontFamily: 'Poppins',
                        )),
                    Text(dates[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: isPast ? AppColors.textLight : AppColors.primary,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
              if (isPast)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Past',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                          fontFamily: 'Poppins')),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegimeCompare() {
    final rowLabels = [
      'Standard Deduction',
      'Section 80C',
      'HRA Exemption',
      'Tax Rebate (87A)',
      'Basic Exemption',
      'NPS (80CCD)',
    ];
    final oldRegime = [
      '₹50,000',
      'Up to ₹1.5L',
      'Available',
      'Up to ₹5L income',
      '₹2.5 lakh',
      'Additional ₹50K',
    ];
    final newRegime = [
      '₹75,000',
      'Not available',
      'Not available',
      'Up to ₹7L income',
      '₹3 lakh',
      'Not available',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: SizedBox()),
                Expanded(
                  flex: 3,
                  child: Text('Old Regime',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          fontSize: 13)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('New Regime',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(rowLabels.length, (i) {
            return Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: i.isEven ? AppColors.surface : AppColors.cardBg,
                border: Border.all(color: AppColors.divider),
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(10))
                    : i == rowLabels.length - 1
                    ? const BorderRadius.vertical(
                    bottom: Radius.circular(10))
                    : BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(rowLabels[i],
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            fontFamily: 'Poppins')),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(oldRegime[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMid,
                            fontFamily: 'Poppins')),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(newRegime[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMid,
                            fontFamily: 'Poppins')),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          InfoCard(
            child: const Text(
              'Tip: If your total deductions exceed ₹3.75 lakh, Old Regime is likely better. Otherwise, opt for the New Regime.',
              style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMid,
                  fontFamily: 'Poppins',
                  height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxResultCard extends StatelessWidget {
  final String label;
  final double amount;
  final bool highlight;
  final String highlightLabel;

  const _TaxResultCard({
    required this.label,
    required this.amount,
    required this.highlight,
    required this.highlightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: highlight ? AppColors.accent : AppColors.divider,
            width: highlight ? 1.5 : 1),
      ),
      child: Column(
        children: [
          if (highlight)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(highlightLabel,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600)),
            ),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMid,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.accent : AppColors.textDark,
              fontFamily: 'Poppins',
            ),
          ),
          const Text('per year',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}