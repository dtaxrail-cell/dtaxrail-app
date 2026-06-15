import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart';
import '../theme/app_theme.dart';
import 'members_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _Slab {
  final double from;
  final double? to;
  final double rate;
  const _Slab({required this.from, this.to, required this.rate});

  factory _Slab.fromJson(Map<String, dynamic> j) => _Slab(
    from: (j['from'] as num).toDouble(),
    to: j['to'] != null ? (j['to'] as num).toDouble() : null,
    rate: (j['rate'] as num).toDouble(),
  );
}

class _RegimeCfg {
  final double standardDeduction;
  final double rebateLimit;
  final List<_Slab> slabs;
  const _RegimeCfg(
      {required this.standardDeduction,
        required this.rebateLimit,
        required this.slabs});

  factory _RegimeCfg.fromJson(Map<String, dynamic> j) => _RegimeCfg(
    standardDeduction: (j['standardDeduction'] as num).toDouble(),
    rebateLimit: (j['rebateLimit'] as num).toDouble(),
    slabs:
    (j['slabs'] as List).map((s) => _Slab.fromJson(s)).toList(),
  );
}

class _YearConfig {
  final String financialYear;
  final _RegimeCfg newRegime;
  final Map<String, _RegimeCfg> oldRegime;
  final Map<String, double> sliderLimits;
  final Map<String, String> personaMessages;

  const _YearConfig({
    required this.financialYear,
    required this.newRegime,
    required this.oldRegime,
    required this.sliderLimits,
    required this.personaMessages,
  });

  factory _YearConfig.fromJson(Map<String, dynamic> j) => _YearConfig(
    financialYear: j['financialYear'] as String,
    newRegime: _RegimeCfg.fromJson(j['newRegime']),
    oldRegime: {
      'general': _RegimeCfg.fromJson(j['oldRegime']['general']),
      'senior': _RegimeCfg.fromJson(j['oldRegime']['senior']),
      'super_senior':
      _RegimeCfg.fromJson(j['oldRegime']['super_senior']),
    },
    sliderLimits: {
      'incomeMax':
      (j['sliderLimits']['incomeMax'] as num).toDouble(),
      'allowancesMax':
      (j['sliderLimits']['allowancesMax'] as num).toDouble(),
      'deductionsMax':
      (j['sliderLimits']['deductionsMax'] as num).toDouble(),
      'npsMax': (j['sliderLimits']['npsMax'] as num).toDouble(),
      'tdsMax': (j['sliderLimits']['tdsMax'] as num).toDouble(),
    },
    personaMessages:
    Map<String, String>.from(j['personaMessages'] ?? {}),
  );

  double limit(String key, double fallback) =>
      sliderLimits[key] ?? fallback;
}

// ─────────────────────────────────────────────────────────────────────────────
// TAX CALCULATION
// ─────────────────────────────────────────────────────────────────────────────

int _calcTax(double taxableIncome, _RegimeCfg cfg) {
  if (taxableIncome <= 0) return 0;

  double tax = 0;
  for (final slab in cfg.slabs) {
    final from = slab.from;
    final to = slab.to ?? taxableIncome;
    if (taxableIncome <= from) break;
    final chunk = (taxableIncome < to ? taxableIncome : to) - from;
    if (chunk > 0) tax += chunk * (slab.rate / 100);
  }

  if (taxableIncome <= cfg.rebateLimit) tax = 0;

  double surcharge = 0;
  if (taxableIncome > 20000000)
    surcharge = tax * 0.25;
  else if (taxableIncome > 10000000)
    surcharge = tax * 0.15;
  else if (taxableIncome > 5000000)
    surcharge = tax * 0.10;

  return ((tax + surcharge) * 1.04).round();
}

// ─────────────────────────────────────────────────────────────────────────────
// FORMATTERS
// ─────────────────────────────────────────────────────────────────────────────

String _fmt(double v) {
  final n = v.abs();
  if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(1)}Cr';
  if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
  if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(0)}K';
  return '₹${n.toStringAsFixed(0)}';
}

String _fmtFull(double v) {
  final s = v.abs().toStringAsFixed(0);
  final buf = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    if (count > 0 &&
        (count == 3 || (count > 3 && (count - 3) % 2 == 0)))
      buf.write(',');
    buf.write(s[i]);
    count++;
  }
  return '₹${buf.toString().split('').reversed.join()}';
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN — list of 5 calculator sections, each navigates to its own screen
// ─────────────────────────────────────────────────────────────────────────────

class TaxToolsScreen extends StatelessWidget {
  const TaxToolsScreen({super.key});

  static final List<_CalcMeta> _calcs = [
    _CalcMeta(
      number: '01',
      title: 'Income Tax Calculator',
      subtitle:
      'Compare New vs Old regime and find your best tax option',
      icon: Icons.calculate_rounded,
      builder: (_) => const _ITRCalculatorScreen(),
    ),
    _CalcMeta(
      number: '02',
      title: 'HRA Exemption Calculator',
      subtitle:
      'Calculate your House Rent Allowance tax exemption under Sec 10(13A)',
      icon: Icons.home_rounded,
      builder: (_) => const _HraCalculatorScreen(),
    ),
    _CalcMeta(
      number: '03',
      title: 'Home & Personal Loan EMI Calculator',
      subtitle:
      'Estimate your monthly EMI, total interest and repayment amount',
      icon: Icons.account_balance_rounded,
      builder: (_) => const _EmiCalculatorScreen(),
    ),
    _CalcMeta(
      number: '04',
      title: 'Systematic Investment Plan (SIP) Calculator',
      subtitle:
      'Project your mutual fund wealth with monthly SIP investments',
      icon: Icons.trending_up_rounded,
      builder: (_) => const _SipCalculatorScreen(),
    ),
    _CalcMeta(
      number: '05',
      title: 'Present Value & Future Value Calculator',
      subtitle:
      'Understand the time value of money — inflation and compound growth',
      icon: Icons.timeline_rounded,
      builder: (_) => const _PvFvCalculatorScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        title: const Text(
          'Tax Tools',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: _calcs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final meta = _calcs[index];
              return _CalcListTile(meta: meta);
            },
          ),
        ),
      ),
    );
  }
}

class _CalcMeta {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;

  const _CalcMeta({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST TILE — tappable card that navigates to the calculator screen
// ─────────────────────────────────────────────────────────────────────────────

class _CalcListTile extends StatelessWidget {
  final _CalcMeta meta;
  const _CalcListTile({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: meta.builder),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(meta.icon,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          meta.number,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            meta.title,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                fontFamily: 'Poppins',
                                height: 1.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meta.subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontFamily: 'Poppins',
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textLight, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SCAFFOLD WRAPPER FOR EACH CALC SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _CalcScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _CalcScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. INCOME TAX CALCULATOR — SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _ITRCalculatorScreen extends StatelessWidget {
  const _ITRCalculatorScreen();

  @override
  Widget build(BuildContext context) {
    return const _CalcScaffold(
      title: 'Income Tax Calculator',
      child: _ITRCalculator(),
    );
  }
}

class _ITRCalculator extends StatefulWidget {
  const _ITRCalculator();

  @override
  State<_ITRCalculator> createState() => _ITRCalculatorState();
}

class _ITRCalculatorState extends State<_ITRCalculator> {
  bool _yearsLoading = true;
  bool _configLoading = false;
  String? _error;

  List<String> _availableYears = [];
  String _selectedYear = '';
  _YearConfig? _config;

  String _persona = 'salaried';
  String _age = 'general';

  double _grossIncome = 0;
  double _exemptions = 0;
  double _deductions = 0;
  double _nps = 0;
  double _tdsPaid = 0;

  double get _incomeMax =>
      _config?.limit('incomeMax', 5000000) ?? 5000000;
  double get _allowancesMax =>
      _config?.limit('allowancesMax', 3000000) ?? 3000000;
  double get _deductionsMax =>
      _config?.limit('deductionsMax', 3000000) ?? 3000000;
  double get _npsMax =>
      _config?.limit('npsMax', 1000000) ?? 1000000;
  double get _tdsMax =>
      _config?.limit('tdsMax', 2500000) ?? 2500000;

  double get _netIncomeNew {
    if (_config == null) return 0;
    final stdDed =
    _persona == 'salaried' ? _config!.newRegime.standardDeduction : 0.0;
    final npsDed = _persona == 'salaried' ? _nps : 0.0;
    return (_grossIncome - npsDed - stdDed).clamp(0.0, double.infinity);
  }

  double get _netIncomeOld {
    if (_config == null) return 0;
    final oldCfg = _config!.oldRegime[_age]!;
    final stdDed =
    _persona == 'salaried' ? oldCfg.standardDeduction : 0.0;
    return (_grossIncome - _exemptions - stdDed - _deductions - _nps)
        .clamp(0.0, double.infinity);
  }

  int get _taxNew =>
      _config == null ? 0 : _calcTax(_netIncomeNew, _config!.newRegime);
  int get _taxOldGeneral => _config == null
      ? 0
      : _calcTax(_netIncomeOld, _config!.oldRegime['general']!);
  int get _taxOldSenior => _config == null
      ? 0
      : _calcTax(_netIncomeOld, _config!.oldRegime['senior']!);
  int get _taxOldSuperSenior => _config == null
      ? 0
      : _calcTax(_netIncomeOld, _config!.oldRegime['super_senior']!);

  int get _taxOld =>
      _age == 'senior'
          ? _taxOldSenior
          : _age == 'super_senior'
          ? _taxOldSuperSenior
          : _taxOldGeneral;

  double get _refundNew => _tdsPaid - _taxNew;
  double get _refundOld => _tdsPaid - _taxOld;
  bool get _newIsBetter => _taxNew <= _taxOld;
  double get _saving => (_taxOld - _taxNew).abs().toDouble();

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    setState(() {
      _grossIncome = 0;
      _exemptions = 0;
      _deductions = 0;
      _nps = 0;
      _tdsPaid = 0;
      _persona = 'salaried';
      _age = 'general';
      _yearsLoading = true;
      _error = null;
    });

    try {
      final res =
      await Dio().get('${ApiConfig.baseUrl}/tax-tools/years');
      final raw = res.data['years'] as List? ?? [];
      final years = raw
          .map((y) => y['financial_year'] as String)
          .toList()
        ..sort((a, b) => a.compareTo(b));

      setState(() {
        _availableYears = years;
        _yearsLoading = false;
      });

      if (years.isNotEmpty) await _loadConfig(years.last);
    } catch (e) {
      setState(() {
        _yearsLoading = false;
        _error = 'Failed to load years. Tap to retry.';
      });
    }
  }

  Future<void> _loadConfig(String year) async {
    setState(() {
      _configLoading = true;
      _error = null;
    });
    try {
      final res = await Dio().get(
          '${ApiConfig.baseUrl}/tax-tools/config/${Uri.encodeComponent(year)}');
      final cfg =
      _YearConfig.fromJson(res.data['config'] as Map<String, dynamic>);

      setState(() {
        _selectedYear = year;
        _config = cfg;
        _configLoading = false;
        _grossIncome = _grossIncome.clamp(0.0, _incomeMax);
        _exemptions = _exemptions.clamp(0.0, _allowancesMax);
        _deductions = _deductions.clamp(0.0, _deductionsMax);
        _nps = _nps.clamp(0.0, _npsMax);
        _tdsPaid = _tdsPaid.clamp(0.0, _tdsMax);
      });
    } catch (e) {
      setState(() {
        _configLoading = false;
        _error = 'Failed to load config for $year.';
      });
    }
  }

  void _goToFiling() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MembersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_yearsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _availableYears.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _loadYears, child: const Text('Retry')),
          ],
        ),
      );
    }

    return _configLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerCard(),
        const SizedBox(height: 16),
        _sectionLabel('Filing Profile'),
        const SizedBox(height: 8),
        _personaSelector(),
        const SizedBox(height: 16),
        _sectionLabel('Age Category'),
        const SizedBox(height: 8),
        _ageSelector(),
        const SizedBox(height: 20),
        _SliderInput(
            label: 'Gross Annual Income',
            value: _grossIncome,
            max: _incomeMax,
            step: 25000,
            onChange: (v) => setState(() => _grossIncome = v)),
        const SizedBox(height: 16),
        _SliderInput(
            label: 'Exempted Allowances (HRA, LTA, etc.)',
            value: _exemptions,
            max: _allowancesMax,
            step: 5000,
            onChange: (v) => setState(() => _exemptions = v)),
        const SizedBox(height: 16),
        _SliderInput(
            label:
            'Deductions (80C, 80D, etc.) — excl. Std. & NPS',
            value: _deductions,
            max: _deductionsMax,
            step: 5000,
            onChange: (v) => setState(() => _deductions = v)),
        const SizedBox(height: 16),
        _SliderInput(
            label: 'NPS Contribution (Sec 80CCD2)',
            value: _nps,
            max: _npsMax,
            step: 5000,
            onChange: (v) => setState(() => _nps = v)),
        const SizedBox(height: 16),
        _SliderInput(
            label: 'TDS / Tax Already Paid',
            value: _tdsPaid,
            max: _tdsMax,
            step: 5000,
            onChange: (v) => setState(() => _tdsPaid = v)),
        const SizedBox(height: 20),
        _sectionLabel('Net Taxable Income'),
        const SizedBox(height: 8),
        _netIncomeCards(),
        const SizedBox(height: 16),
        _sectionLabel('Tax Comparison'),
        const SizedBox(height: 8),
        _taxComparisonCard(),
        const SizedBox(height: 16),
        _sectionLabel('Estimated Refund / Payment Due'),
        const SizedBox(height: 8),
        _refundCards(),
        const SizedBox(height: 20),
        _ctaSection(),
        const SizedBox(height: 16),
        Text(
          '* Estimates based on FY $_selectedYear IT Act slabs. Std. deduction ₹75,000 (New) / ₹50,000 (Old) auto-applied. Includes 4% cess + surcharge where applicable. Consult a CA for final filing.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMid,
              height: 1.5),
        ),
      ],
    );
  }

  // ── Header card — FY label fix ────────────────────────────────────────

  Widget _headerCard() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: const Color(0xFF0C1B33),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calculate_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Income Tax Calculator',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Poppins')),
                Text('Tax Estimator · Real-Time',
                    style: TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 10,
                        fontFamily: 'monospace')),
              ],
            ),
          ),
          if (_availableYears.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _availableYears.map((yr) {
                    final sel = _selectedYear == yr;
                    // ✅ Display as "FY 2025-26" instead of "2025-26"
                    return GestureDetector(
                      onTap: () {
                        if (!sel) _loadConfig(yr);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'FY $yr',
                          style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF93C5FD),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace'),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMid,
        letterSpacing: 0.5,
        fontFamily: 'Poppins'),
  );

  Widget _personaSelector() {
    final opts = [
      ('salaried', '💼 Salaried'),
      ('freelancer', '🚀 Freelancer'),
      ('merchant', '🏪 Business')
    ];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: opts.map((opt) {
          final sel = _persona == opt.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _persona = opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: sel
                      ? [
                    BoxShadow(
                        color:
                        Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4)
                  ]
                      : [],
                ),
                child: Text(opt.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel
                            ? AppColors.primary
                            : AppColors.textMid,
                        fontFamily: 'Poppins')),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _ageSelector() {
    final opts = [
      ('general', 'General', '< 60 yrs'),
      ('senior', 'Senior', '60–79 yrs'),
      ('super_senior', 'Super Sr.', '80+ yrs')
    ];
    return Row(
      children: opts.map((opt) {
        final sel = _age == opt.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _age = opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                  right: opt.$1 == 'super_senior' ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFFEFF6FF)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                    sel ? AppColors.primary : AppColors.divider,
                    width: sel ? 1.5 : 1),
              ),
              child: Column(
                children: [
                  Text(opt.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: sel
                              ? AppColors.primary
                              : AppColors.textMid,
                          fontFamily: 'Poppins')),
                  const SizedBox(height: 2),
                  Text(opt.$3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 9,
                          color: sel
                              ? AppColors.primary
                              .withValues(alpha: 0.7)
                              : AppColors.textLight,
                          fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _netIncomeCards() {
    return Row(
      children: [
        Expanded(
            child: _infoCard(
                label: 'NET INCOME · NEW',
                value: _fmtFull(_netIncomeNew),
                sub: _persona == 'salaried'
                    ? 'Std. deduction ₹75,000 applied'
                    : 'No standard deduction',
                bgColor: const Color(0xFFEFF6FF),
                border: const Color(0xFFBFDBFE),
                lblColor: const Color(0xFF3B82F6),
                valColor: const Color(0xFF1D4ED8))),
        const SizedBox(width: 10),
        Expanded(
            child: _infoCard(
                label: 'NET INCOME · OLD',
                value: _fmtFull(_netIncomeOld),
                sub: _persona == 'salaried'
                    ? 'Std. ₹50,000 & deductions'
                    : 'Deductions applied',
                bgColor: const Color(0xFFEEF2FF),
                border: const Color(0xFFC7D2FE),
                lblColor: const Color(0xFF6366F1),
                valColor: const Color(0xFF4338CA))),
      ],
    );
  }

  Widget _infoCard(
      {required String label,
        required String value,
        required String sub,
        required Color bgColor,
        required Color border,
        required Color lblColor,
        required Color valColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: lblColor,
                letterSpacing: 0.5,
                fontFamily: 'monospace')),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valColor,
                fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(sub,
            style:
            TextStyle(fontSize: 9, color: lblColor.withValues(alpha: 0.7))),
      ]),
    );
  }

  Widget _taxComparisonCard() {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider)),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                    child: _regimeColumn(
                        label: 'New Regime',
                        tax: _taxNew,
                        isBetter: _newIsBetter,
                        showBreakdown: false)),
                Container(width: 1, color: AppColors.divider),
                Expanded(
                    child: _regimeColumn(
                        label: 'Old Regime',
                        tax: _taxOld,
                        isBetter: !_newIsBetter,
                        showBreakdown: true)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _newIsBetter
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFFFBEB),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(
                  top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    _newIsBetter
                        ? '✓ New Regime saves you'
                        : '✓ Old Regime saves you',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontFamily: 'Poppins')),
                Text(_fmtFull(_saving),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _newIsBetter
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _regimeColumn(
      {required String label,
        required int tax,
        required bool isBetter,
        required bool showBreakdown}) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isBetter
                        ? const Color(0xFF22C55E)
                        : AppColors.divider)),
            const SizedBox(width: 6),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMid,
                        fontFamily: 'monospace'))),
            if (isBetter)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Better ✓',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D))),
              ),
          ]),
          const SizedBox(height: 6),
          const Text('Tax Liability',
              style: TextStyle(fontSize: 9, color: AppColors.textMid)),
          const SizedBox(height: 2),
          Text(_fmtFull(tax.toDouble()),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isBetter
                      ? const Color(0xFF16A34A)
                      : AppColors.textDark,
                  fontFamily: 'Poppins')),
          if (showBreakdown) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (_age != 'general')
              _ageRow('General (<60)', _taxOldGeneral),
            if (_age != 'senior')
              _ageRow('Senior (60-79)', _taxOldSenior),
            if (_age != 'super_senior')
              _ageRow('Super Sr. (80+)', _taxOldSuperSenior),
          ],
        ],
      ),
    );
  }

  Widget _ageRow(String label, int tax) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textLight)),
          Text(_fmt(tax.toDouble()),
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textLight)),
        ]),
  );

  Widget _refundCards() => Row(children: [
    Expanded(
        child:
        _refundCard(label: 'New Regime', refund: _refundNew)),
    const SizedBox(width: 10),
    Expanded(
        child:
        _refundCard(label: 'Old Regime', refund: _refundOld)),
  ]);

  Widget _refundCard(
      {required String label, required double refund}) {
    final isRefund = refund >= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRefund
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isRefund
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFFECACA)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: isRefund
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
                fontFamily: 'monospace',
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(
            isRefund
                ? '+${_fmtFull(refund)}'
                : '-${_fmtFull(refund.abs())}',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isRefund
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
                fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(isRefund ? 'Refund Expected' : 'Tax Due',
            style: TextStyle(
                fontSize: 9,
                color: isRefund
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626))),
      ]),
    );
  }

  Widget _ctaSection() {
    if (_persona == 'salaried') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _goToFiling,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Finalise Tax & File ITR Now',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 14),
          ),
        ),
      );
    }
    if (_persona == 'freelancer') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A))),
        child: Column(children: [
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.bolt_rounded, color: Color(0xFFB45309), size: 16),
            SizedBox(width: 6),
            Expanded(
                child: Text(
                    "Since you're a freelancer, please reach out to our professionals for accurate tax filing",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                        fontFamily: 'Poppins'))),
          ]),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _goToFiling,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Talk to a CA Expert',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    fontSize: 12)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC7D2FE))),
      child: Column(children: [
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bolt_rounded, color: Color(0xFF4338CA), size: 16),
          SizedBox(width: 6),
          Expanded(
              child: Text(
                  'Since you fall under sole proprietor / business profile, please reach out to us for accurate tax filing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4338CA),
                      fontFamily: 'Poppins'))),
        ]),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _goToFiling,
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('Get Expert Help',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  fontSize: 12)),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. HRA EXEMPTION CALCULATOR — SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _HraCalculatorScreen extends StatelessWidget {
  const _HraCalculatorScreen();

  @override
  Widget build(BuildContext context) {
    return const _CalcScaffold(
      title: 'HRA Exemption Calculator',
      child: _HraCalculator(),
    );
  }
}

class _HraCalculator extends StatefulWidget {
  const _HraCalculator();
  @override
  State<_HraCalculator> createState() => _HraCalculatorState();
}

class _HraCalculatorState extends State<_HraCalculator> {
  double _basicSalary = 0;
  double _da = 0;
  double _hraReceived = 0;
  double _rentPaid = 0;
  bool _isMetro = true;

  static const _metroOptions = [
    ('Delhi', true), ('Mumbai', true), ('Kolkata', true),
    ('Chennai', true), ('Bangalore', false), ('Hyderabad', false),
    ('Pune', false), ('Other', false),
  ];
  String _selectedCity = 'Delhi';

  double get _totalSalary => _basicSalary + _da;
  double get _rentExcess =>
      (_rentPaid - 0.1 * _totalSalary).clamp(0, double.infinity);
  double get _basicPct => (_isMetro ? 0.5 : 0.4) * _totalSalary;
  double get _exemption =>
      [_hraReceived, _rentExcess, _basicPct].reduce((a, b) => a < b ? a : b);
  double get _taxableHra =>
      (_hraReceived - _exemption).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderInput(
              label: 'Basic Salary (Annual)',
              value: _basicSalary,
              max: 5000000,
              step: 10000,
              onChange: (v) => setState(() => _basicSalary = v)),
          const SizedBox(height: 14),
          _SliderInput(
              label: 'Dearness Allowance — DA (Annual)',
              value: _da,
              max: 2000000,
              step: 5000,
              onChange: (v) => setState(() => _da = v)),
          const SizedBox(height: 14),
          _SliderInput(
              label: 'HRA Received (Annual)',
              value: _hraReceived,
              max: 2000000,
              step: 5000,
              onChange: (v) => setState(() => _hraReceived = v)),
          const SizedBox(height: 14),
          _SliderInput(
              label: 'Total Rent Paid (Annual)',
              value: _rentPaid,
              max: 2500000,
              step: 5000,
              onChange: (v) => setState(() => _rentPaid = v)),
          const SizedBox(height: 16),

          // City picker
          const Text('City of Residence',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _metroOptions.map((opt) {
              final sel = _selectedCity == opt.$1;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCity = opt.$1;
                  _isMetro = opt.$2;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : AppColors.divider),
                  ),
                  child: Text(opt.$1,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textMid,
                          fontFamily: 'Poppins')),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                    _isMetro ? Colors.green : Colors.orange)),
            const SizedBox(width: 6),
            Text(
                _isMetro
                    ? 'Metro City — 50% HRA limit applies'
                    : 'Non-Metro City — 40% HRA limit applies',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                    fontFamily: 'Poppins')),
          ]),
          const SizedBox(height: 16),

          // Results
          Row(children: [
            Expanded(
                child: _resultChip(
                    label: 'EXEMPTED HRA',
                    value: _fmtFull(_exemption),
                    sub: 'Tax-Free · Sec 10(13A)',
                    bg: const Color(0xFFF0FDF4),
                    border: const Color(0xFFBBF7D0),
                    textColor: const Color(0xFF16A34A))),
            const SizedBox(width: 10),
            Expanded(
                child: _resultChip(
                    label: 'TAXABLE HRA',
                    value: _fmtFull(_taxableHra),
                    sub: 'Added to gross income',
                    bg: const Color(0xFFFFFBEB),
                    border: const Color(0xFFFDE68A),
                    textColor: const Color(0xFFB45309))),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exemption Limit Summary',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                        fontFamily: 'Poppins')),
                const SizedBox(height: 6),
                const Text(
                    'HRA exemption is the lowest of:\n'
                        '  1. Actual HRA received\n'
                        '  2. Rent paid minus 10% of Basic+DA\n'
                        '  3. 50% (Metro) or 40% (Non-Metro) of Basic+DA',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMid,
                        height: 1.6)),
                const SizedBox(height: 10),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Actual HRA',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMid)),
                      Text(_fmtFull(_hraReceived),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ]),
                const SizedBox(height: 4),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rent excess (>10% salary)',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMid)),
                      Text(_fmtFull(_rentExcess),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ]),
                const SizedBox(height: 4),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${_isMetro ? "50%" : "40%"} of Basic+DA',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMid)),
                      Text(_fmtFull(_basicPct),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultChip(
      {required String label,
        required String value,
        required String sub,
        required Color bg,
        required Color border,
        required Color textColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.5,
                fontFamily: 'monospace')),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
                fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(sub,
            style: TextStyle(
                fontSize: 9, color: textColor.withValues(alpha: 0.7))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. EMI CALCULATOR — SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _EmiCalculatorScreen extends StatelessWidget {
  const _EmiCalculatorScreen();

  @override
  Widget build(BuildContext context) {
    return const _CalcScaffold(
      title: 'EMI Calculator',
      child: _EmiCalculator(),
    );
  }
}

class _EmiCalculator extends StatefulWidget {
  const _EmiCalculator();
  @override
  State<_EmiCalculator> createState() => _EmiCalculatorState();
}

class _EmiCalculatorState extends State<_EmiCalculator> {
  double _principal = 0;
  double _rate = 0;
  double _tenure = 0;

  double get _monthlyRate => _rate / (12 * 100);
  int get _months => (_tenure * 12).round();

  double get _emi {
    if (_months == 0) return 0;
    if (_monthlyRate == 0) return _principal / _months;
    final r = _monthlyRate;
    final n = _months;
    return (_principal * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  double get _totalPayable => _emi * _months;
  double get _totalInterest => (_totalPayable - _principal).clamp(0, double.infinity);

  double pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderInput(
              label: 'Loan Principal Amount',
              value: _principal,
              max: 15000000,
              step: 50000,
              onChange: (v) => setState(() => _principal = v)),
          const SizedBox(height: 14),
          _SliderInput(
              label: 'Annual Interest Rate (%)',
              value: _rate,
              max: 20,
              step: 0.1,
              isCurrency: false,
              suffix: '%',
              onChange: (v) => setState(() => _rate = v)),
          const SizedBox(height: 14),
          _SliderInput(
              label: 'Loan Tenure (Years)',
              value: _tenure,
              max: 30,
              step: 1,
              isCurrency: false,
              suffix: 'Y',
              onChange: (v) => setState(() => _tenure = v)),
          const SizedBox(height: 20),

          // EMI highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF0C1B33),
                borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              const Text('MONTHLY EMI PAYMENT',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF93C5FD),
                      fontFamily: 'monospace',
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(_fmtFull(_emi),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Poppins')),
            ]),
          ),
          const SizedBox(height: 14),

          Row(children: [
            Expanded(
                child: _miniCard('Principal', _fmtFull(_principal),
                    const Color(0xFF3B82F6))),
            const SizedBox(width: 8),
            Expanded(
                child: _miniCard('Total Interest', _fmtFull(_totalInterest),
                    const Color(0xFFEF4444))),
            const SizedBox(width: 8),
            Expanded(
                child: _miniCard('Total Amount', _fmtFull(_totalPayable),
                    AppColors.textDark)),
          ]),
          const SizedBox(height: 14),
          _progressBar(
              leftPct: _totalPayable > 0
                  ? _totalInterest / _totalPayable
                  : 0,
              leftColor: const Color(0xFFEF4444),
              rightColor: const Color(0xFF3B82F6),
              leftLabel:
              'Interest ${_totalPayable > 0 ? ((_totalInterest / _totalPayable) * 100).round() : 0}%',
              rightLabel:
              'Principal ${_totalPayable > 0 ? ((_principal / _totalPayable) * 100).round() : 0}%'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. SIP CALCULATOR — SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _SipCalculatorScreen extends StatelessWidget {
  const _SipCalculatorScreen();

  @override
  Widget build(BuildContext context) {
    return const _CalcScaffold(
      title: 'SIP Calculator',
      child: _SipCalculator(),
    );
  }
}

class _SipCalculator extends StatefulWidget {
  const _SipCalculator();
  @override
  State<_SipCalculator> createState() => _SipCalculatorState();
}

class _SipCalculatorState extends State<_SipCalculator> {
  double _monthly = 0;
  double _rate = 0;
  double _tenure = 0;

  double get _monthlyRate => _rate / (12 * 100);
  int get _months => (_tenure * 12).round();

  double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }

  double get _fv {
    if (_months == 0) return 0;
    if (_monthlyRate == 0) return _monthly * _months;
    return _monthly *
        ((_pow(1 + _monthlyRate, _months) - 1) / _monthlyRate) *
        (1 + _monthlyRate);
  }

  double get _totalInvested => _monthly * _months;
  double get _returns => (_fv - _totalInvested).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SliderInput(
              label: 'Monthly Investment Amount',
              value: _monthly,
              max: 500000,
              step: 500,
              onChange: (v) => setState(() => _monthly = v)),
          const SizedBox(height: 14),
          _SliderInput(
              label: 'Expected Annual Return Rate (%)',
              value: _rate,
              max: 30,
              step: 0.5,
              isCurrency: false,
              suffix: '%',
              onChange: (v) => setState(() => _rate = v)),
          const SizedBox(height: 14),
          _SliderInput(
              label: 'Investment Duration (Years)',
              value: _tenure,
              max: 40,
              step: 1,
              isCurrency: false,
              suffix: 'Y',
              onChange: (v) => setState(() => _tenure = v)),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF0C1B33),
                borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              const Text('ESTIMATED FUTURE WEALTH',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6EE7B7),
                      fontFamily: 'monospace',
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(_fmtFull(_fv),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Poppins')),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _miniCard(
                    'Invested', _fmtFull(_totalInvested), const Color(0xFF3B82F6))),
            const SizedBox(width: 8),
            Expanded(
                child: _miniCard(
                    'Est. Returns', _fmtFull(_returns), const Color(0xFF16A34A))),
          ]),
          const SizedBox(height: 14),
          _progressBar(
              leftPct:
              _fv > 0 ? _totalInvested / _fv : 0,
              leftColor: const Color(0xFF3B82F6),
              rightColor: const Color(0xFF16A34A),
              leftLabel:
              'Invested ${_fv > 0 ? ((_totalInvested / _fv) * 100).round() : 0}%',
              rightLabel:
              'Returns ${_fv > 0 ? ((_returns / _fv) * 100).round() : 0}%'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. PV / FV CALCULATOR — SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _PvFvCalculatorScreen extends StatelessWidget {
  const _PvFvCalculatorScreen();

  @override
  Widget build(BuildContext context) {
    return const _CalcScaffold(
      title: 'Present / Future Value Calculator',
      child: _PvFvCalculator(),
    );
  }
}

class _PvFvCalculator extends StatefulWidget {
  const _PvFvCalculator();
  @override
  State<_PvFvCalculator> createState() => _PvFvCalculatorState();
}

class _PvFvCalculatorState extends State<_PvFvCalculator> {
  bool _isPvMode = true; // true = find PV from FV, false = find FV from PV
  double _amount = 0;
  double _rate = 0;
  double _tenure = 0;

  double _pow(double base, double exp) {
    if (base <= 0) return 1;
    return base == 1 ? 1 : _expPow(base, exp);
  }

  double _expPow(double base, double exp) {
    // Approximate: base^exp = e^(exp * ln(base))
    double ln = 0;
    double x = (base - 1) / (base + 1);
    double term = x;
    for (int i = 1; i <= 50; i++) {
      ln += term / (2 * i - 1);
      term *= x * x;
    }
    ln *= 2;
    double result = 1, expVal = exp * ln;
    double factTerm = 1;
    for (int i = 1; i <= 20; i++) {
      factTerm *= expVal / i;
      result += factTerm;
    }
    return result;
  }

  double get _discountRate => _rate / 100;

  double get _result {
    if (_tenure == 0) return _amount;
    final factor = _pow(1 + _discountRate, _tenure);
    return _isPvMode ? (_amount / factor) : (_amount * factor);
  }

  double get _difference => (_amount - _result).abs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPvMode = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: _isPvMode
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _isPvMode
                              ? [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.08),
                                blurRadius: 4)
                          ]
                              : []),
                      child: Text('Present Value\n(from Future Sum)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _isPvMode
                                  ? AppColors.primary
                                  : AppColors.textMid,
                              fontFamily: 'Poppins')),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPvMode = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: !_isPvMode
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: !_isPvMode
                              ? [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.08),
                                blurRadius: 4)
                          ]
                              : []),
                      child: Text('Future Value\n(from Present Sum)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: !_isPvMode
                                  ? AppColors.primary
                                  : AppColors.textMid,
                              fontFamily: 'Poppins')),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SliderInput(
              label: _isPvMode
                  ? 'Future Target Value (FV)'
                  : 'Present Amount (PV)',
              value: _amount,
              max: 15000000,
              step: 10000,
              onChange: (v) => setState(() => _amount = v)),
          const SizedBox(height: 14),
          _SliderInput(
              label: 'Annual Rate — Inflation / Growth (%)',
              value: _rate,
              max: 25,
              step: 0.5,
              isCurrency: false,
              suffix: '%',
              onChange: (v) => setState(() => _rate = v)),
          const SizedBox(height: 14),
          _SliderInput(
              label: 'Time Duration (Years)',
              value: _tenure,
              max: 40,
              step: 1,
              isCurrency: false,
              suffix: 'Y',
              onChange: (v) => setState(() => _tenure = v)),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF0C1B33),
                borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text(
                  _isPvMode
                      ? 'CALCULATED PRESENT VALUE (WORTH TODAY)'
                      : 'CALCULATED FUTURE VALUE',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFCA5A5),
                      fontFamily: 'monospace',
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(_fmtFull(_result),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Poppins')),
            ]),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _isPvMode
                              ? 'Erosion in Purchasing Power'
                              : 'Compound Growth Gained',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      Text(_fmtFull(_difference),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626),
                              fontFamily: 'Poppins')),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                      _isPvMode
                          ? '${_fmtFull(_amount)} in ${_tenure.round()}Y = ${_fmtFull(_result)} in today\'s money at ${_rate.toStringAsFixed(1)}% inflation.'
                          : '${_fmtFull(_amount)} today grows to ${_fmtFull(_result)} in ${_tenure.round()}Y at ${_rate.toStringAsFixed(1)}% compound interest.',
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textMid,
                          height: 1.5,
                          fontFamily: 'Poppins'),
                      textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

Widget _miniCard(String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider)),
    child: Column(children: [
      Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
              fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      Text(value,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'Poppins')),
    ]),
  );
}

Widget _progressBar({
  required double leftPct,
  required Color leftColor,
  required Color rightColor,
  required String leftLabel,
  required String rightLabel,
}) {
  return Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(leftLabel,
          style: const TextStyle(fontSize: 9, color: AppColors.textLight)),
      Text(rightLabel,
          style: const TextStyle(fontSize: 9, color: AppColors.textLight)),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Row(children: [
          Expanded(
              flex: (leftPct * 100).round(),
              child: Container(color: leftColor)),
          Expanded(
              flex: ((1 - leftPct) * 100).round(),
              child: Container(color: rightColor)),
        ]),
      ),
    ),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDER INPUT — fixed: slider stays in sync when focus leaves text field
// ─────────────────────────────────────────────────────────────────────────────

class _SliderInput extends StatefulWidget {
  final String label;
  final double value;
  final double max;
  final double step;
  final bool isCurrency;
  final String suffix;
  final ValueChanged<double> onChange;

  const _SliderInput({
    required this.label,
    required this.value,
    required this.max,
    required this.step,
    required this.onChange,
    this.isCurrency = true,
    this.suffix = '',
  });

  @override
  State<_SliderInput> createState() => _SliderInputState();
}

class _SliderInputState extends State<_SliderInput> {
  late TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _disp(widget.value));
  }

  @override
  void didUpdateWidget(_SliderInput old) {
    super.didUpdateWidget(old);
    // ✅ Always sync the text field when the value changes externally
    // (covers the case where user moves another slider and this one needs updating)
    if (!_editing) {
      final newText = _disp(widget.value);
      if (_ctrl.text != newText) _ctrl.text = newText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _disp(double v) {
    if (!widget.isCurrency) return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+\d$)'), (m) => '${m[1]},');
  }

  String _short(double v) {
    if (!widget.isCurrency) return '${v.toStringAsFixed(0)}${widget.suffix}';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  void _commitText() {
    final raw = _ctrl.text.replaceAll(',', '');
    final parsed = double.tryParse(raw) ?? 0;
    final clamped = parsed.clamp(0.0, widget.max);
    widget.onChange(clamped);
    // ✅ Immediately update display to reflect clamped value
    setState(() {
      _editing = false;
      _ctrl.text = _disp(clamped);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(widget.label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontFamily: 'Poppins'))),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Focus(
              onFocusChange: (focused) {
                if (focused) {
                  setState(() => _editing = true);
                  // Show raw number when editing
                  _ctrl.text = widget.value.toStringAsFixed(
                      widget.isCurrency ? 0 : 1);
                  _ctrl.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _ctrl.text.length);
                } else {
                  // ✅ Commit and sync slider when focus lost
                  _commitText();
                }
              },
              child: TextField(
                controller: _ctrl,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: widget.isCurrency
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.]'))
                ],
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  prefixText: widget.isCurrency ? '₹' : null,
                  suffixText:
                  !widget.isCurrency && widget.suffix.isNotEmpty
                      ? widget.suffix
                      : null,
                  prefixStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                  suffixStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMid),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      const BorderSide(color: AppColors.primary)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.divider)),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(
                      val.replaceAll(',', '')) ??
                      0;
                  widget.onChange(parsed.clamp(0.0, widget.max));
                },
                onSubmitted: (_) => _commitText(),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Listener(
          onPointerDown: (_) {
            // ✅ Forcibly remove focus from whatever text field currently
            // holds it, globally — fires the instant the slider is touched
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 4,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              // ✅ Always reads from widget.value — never stale
              value: widget.value.clamp(0.0, widget.max),
              min: 0,
              max: widget.max,
              divisions: (widget.max / widget.step).round(),
              onChanged: (v) {
                // Moving slider clears editing mode and syncs text
                if (_editing) setState(() => _editing = false);
                widget.onChange(v);
                _ctrl.text = _disp(v);
              },
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_short(0),
              style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textLight,
                  fontFamily: 'monospace')),
          Text(_short(widget.max),
              style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textLight,
                  fontFamily: 'monospace')),
        ]),
      ],
    );
  }
}