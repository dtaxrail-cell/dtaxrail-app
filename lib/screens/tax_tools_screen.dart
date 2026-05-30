import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../config/api_config.dart';

class TaxCalculatorScreen extends StatefulWidget {
  const TaxCalculatorScreen({super.key});

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen>
    with WidgetsBindingObserver {
  // ── Config ────────────────────────────────────────────────────────────────
  bool _yearsLoading = true;
  bool _configLoading = false;
  List<String> _availableYears = [];
  Map<String, dynamic>? _config;

  // ── Inputs ────────────────────────────────────────────────────────────────
  String _selectedYear = '';
  String _filingPersona = 'salaried';
  String _ageCategory = 'general';

  double _grossIncome = 0;
  double _exemptedAllowances = 0;
  double _deductions = 0;
  double _npsContribution = 0;
  double _tdsPaid = 0;

  final _incomeCtrl = TextEditingController();
  final _allowancesCtrl = TextEditingController();
  final _deductionsCtrl = TextEditingController();
  final _npsCtrl = TextEditingController();
  final _tdsCtrl = TextEditingController();

  TextEditingController? _activeCtrl;

  // ── Results ───────────────────────────────────────────────────────────────
  bool _calculating = false;
  bool _hasResult = false;
  Map<String, dynamic>? _result;

  // ── Slider maxima (always read live from _config) ─────────────────────────
  double get _incomeMax => _cfg('incomeMax', 5000000);
  double get _allowancesMax => _cfg('allowancesMax', 3000000);
  double get _deductionsMax => _cfg('deductionsMax', 3000000);
  double get _npsMax => _cfg('npsMax', 1000000);
  double get _tdsMax => _cfg('tdsMax', 2500000);

  double _cfg(String key, double fallback) {
    final limits = _config?['sliderLimits'];
    return (limits?[key] as num?)?.toDouble() ?? fallback;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadYears();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _incomeCtrl.dispose();
    _allowancesCtrl.dispose();
    _deductionsCtrl.dispose();
    _npsCtrl.dispose();
    _tdsCtrl.dispose();
    super.dispose();
  }

  /// Re-fetch config when the app comes back to foreground
  /// so admin changes (slabs, slider limits, messages) are always fresh.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _selectedYear.isNotEmpty) {
      _loadYears(keepSelection: true);
    }
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  /// Loads the list of financial years from the backend.
  /// [keepSelection] = true means keep the currently selected year after refresh.
  Future<void> _loadYears({bool keepSelection = false}) async {
    if (!keepSelection) setState(() => _yearsLoading = true);
    try {
      final res = await Dio().get('${ApiConfig.baseUrl}/tax-tools/years');
      final raw = res.data['years'] as List? ?? [];
      // Sort descending so latest year is first
      final years = raw
          .map((y) => y['financial_year'] as String)
          .toList()
        ..sort((a, b) => b.compareTo(a));

      setState(() {
        _availableYears = years;
        _yearsLoading = false;
        if (years.isEmpty) return;

        if (keepSelection && years.contains(_selectedYear)) {
          // Refresh config for current year silently
          _loadConfig(_selectedYear, silent: true);
        } else {
          // First load — pick latest year
          final target = years.first;
          _selectedYear = target;
          _loadConfig(target);
        }
      });
    } catch (e) {
      debugPrint('Failed to load years: $e');
      setState(() => _yearsLoading = false);
    }
  }

  /// Loads the full config (slabs, limits, messages) for [year].
  /// [silent] = true means don't show the full-screen spinner.
  Future<void> _loadConfig(String year, {bool silent = false}) async {
    if (!silent) setState(() => _configLoading = true);
    try {
      final res = await Dio().get(
        '${ApiConfig.baseUrl}/tax-tools/config/${Uri.encodeComponent(year)}',
      );
      if (!mounted) return;
      setState(() {
        _config = Map<String, dynamic>.from(res.data['config'] ?? {});
        _configLoading = false;
        // Clamp existing slider values to new limits in case admin changed them
        _grossIncome = _grossIncome.clamp(0, _incomeMax);
        _exemptedAllowances = _exemptedAllowances.clamp(0, _allowancesMax);
        _deductions = _deductions.clamp(0, _deductionsMax);
        _npsContribution = _npsContribution.clamp(0, _npsMax);
        _tdsPaid = _tdsPaid.clamp(0, _tdsMax);
      });
    } catch (e) {
      debugPrint('Config load error: $e');
      if (mounted) setState(() => _configLoading = false);
    }
  }

  Future<void> _calculate() async {
    setState(() {
      _calculating = true;
      _hasResult = false;
      _result = null;
    });
    try {
      final res = await Dio().post(
        '${ApiConfig.baseUrl}/tax-tools/calculate',
        data: {
          'financialYear': _selectedYear,
          'filingPersona': _filingPersona,
          'ageCategory': _ageCategory,
          'grossIncome': _grossIncome,
          'exemptedAllowances': _exemptedAllowances,
          'deductions': _deductions,
          'npsContribution': _npsContribution,
          'tdsPaid': _tdsPaid,
        },
      );
      if (!mounted) return;
      setState(() {
        _result = Map<String, dynamic>.from(res.data['result'] ?? {});
        _hasResult = true;
        _calculating = false;
      });
    } catch (e) {
      debugPrint('Calculate error: $e');
      if (!mounted) return;
      setState(() => _calculating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calculation failed. Please try again.')),
      );
    }
  }

  // ── Slider ↔ TextField sync ───────────────────────────────────────────────

  void _syncCtrl(TextEditingController ctrl, double value) {
    if (_activeCtrl == ctrl) return;
    final text = value.toStringAsFixed(0);
    if (ctrl.text != text) {
      ctrl.value = ctrl.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  double _parseCtrl(TextEditingController ctrl, double max) {
    final v = double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0;
    return v.clamp(0, max);
  }

  // ── Formatters ────────────────────────────────────────────────────────────

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)} L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _fmtFull(double v) => '₹${v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+\d$)'), (m) => '${m[1]},')}';

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_yearsLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_availableYears.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tax Calculator'), elevation: 0,
            backgroundColor: AppColors.background),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No tax data available.'),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadYears, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tax Calculator'),
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          // Manual refresh button so users can pull latest admin changes
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => _loadYears(keepSelection: true),
          ),
        ],
      ),
      body: _configLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Financial Year ──────────────────────────────────
            _sectionLabel('Financial Year'),
            const SizedBox(height: 8),
            _fySelector(),
            const SizedBox(height: 20),

            // ── Filing Persona ──────────────────────────────────
            _sectionLabel('Filing Persona'),
            const SizedBox(height: 8),
            _personaSelector(),
            const SizedBox(height: 20),

            // ── Age Category ────────────────────────────────────
            _sectionLabel('Age Category'),
            const SizedBox(height: 8),
            _ageSelector(),
            const SizedBox(height: 24),

            // ── Gross Income ────────────────────────────────────
            _sliderInput(
              label: 'Gross Annual Income',
              value: _grossIncome,
              max: _incomeMax,
              ctrl: _incomeCtrl,
              onSliderChanged: (v) => setState(() {
                _grossIncome = v;
                _syncCtrl(_incomeCtrl, v);
              }),
              onTextChanged: (v) =>
                  setState(() => _grossIncome = v.clamp(0, _incomeMax)),
              onFocusChange: (focused) {
                if (focused) {
                  _activeCtrl = _incomeCtrl;
                } else {
                  _activeCtrl = null;
                  setState(() {
                    _grossIncome = _parseCtrl(_incomeCtrl, _incomeMax);
                    _syncCtrl(_incomeCtrl, _grossIncome);
                  });
                }
              },
              hint: 'Slide up to ${_fmt(_incomeMax)}',
            ),
            const SizedBox(height: 18),

            // ── Exempted Allowances ─────────────────────────────
            _sliderInput(
              label: 'Exempted Allowances',
              value: _exemptedAllowances,
              max: _allowancesMax,
              ctrl: _allowancesCtrl,
              onSliderChanged: (v) => setState(() {
                _exemptedAllowances = v;
                _syncCtrl(_allowancesCtrl, v);
              }),
              onTextChanged: (v) => setState(
                      () => _exemptedAllowances = v.clamp(0, _allowancesMax)),
              onFocusChange: (focused) {
                if (focused) {
                  _activeCtrl = _allowancesCtrl;
                } else {
                  _activeCtrl = null;
                  setState(() {
                    _exemptedAllowances =
                        _parseCtrl(_allowancesCtrl, _allowancesMax);
                    _syncCtrl(_allowancesCtrl, _exemptedAllowances);
                  });
                }
              },
              hint: 'Up to ${_fmt(_allowancesMax)}',
            ),
            const SizedBox(height: 18),

            // ── Deductions ──────────────────────────────────────
            _sliderInput(
              label:
              'Deductions (excluding standard deduction and NPS contribution)',
              value: _deductions,
              max: _deductionsMax,
              ctrl: _deductionsCtrl,
              onSliderChanged: (v) => setState(() {
                _deductions = v;
                _syncCtrl(_deductionsCtrl, v);
              }),
              onTextChanged: (v) => setState(
                      () => _deductions = v.clamp(0, _deductionsMax)),
              onFocusChange: (focused) {
                if (focused) {
                  _activeCtrl = _deductionsCtrl;
                } else {
                  _activeCtrl = null;
                  setState(() {
                    _deductions =
                        _parseCtrl(_deductionsCtrl, _deductionsMax);
                    _syncCtrl(_deductionsCtrl, _deductions);
                  });
                }
              },
              hint: 'Up to ${_fmt(_deductionsMax)}',
            ),
            const SizedBox(height: 18),

            // ── NPS ─────────────────────────────────────────────
            _sliderInput(
              label: 'NPS Contribution (if any)',
              value: _npsContribution,
              max: _npsMax,
              ctrl: _npsCtrl,
              onSliderChanged: (v) => setState(() {
                _npsContribution = v;
                _syncCtrl(_npsCtrl, v);
              }),
              onTextChanged: (v) => setState(
                      () => _npsContribution = v.clamp(0, _npsMax)),
              onFocusChange: (focused) {
                if (focused) {
                  _activeCtrl = _npsCtrl;
                } else {
                  _activeCtrl = null;
                  setState(() {
                    _npsContribution = _parseCtrl(_npsCtrl, _npsMax);
                    _syncCtrl(_npsCtrl, _npsContribution);
                  });
                }
              },
              hint: 'Up to ${_fmt(_npsMax)}',
              bold: true,
            ),
            const SizedBox(height: 18),

            // ── TDS ─────────────────────────────────────────────
            _sliderInput(
              label: 'TDS / Tax Already Paid',
              value: _tdsPaid,
              max: _tdsMax,
              ctrl: _tdsCtrl,
              onSliderChanged: (v) => setState(() {
                _tdsPaid = v;
                _syncCtrl(_tdsCtrl, v);
              }),
              onTextChanged: (v) =>
                  setState(() => _tdsPaid = v.clamp(0, _tdsMax)),
              onFocusChange: (focused) {
                if (focused) {
                  _activeCtrl = _tdsCtrl;
                } else {
                  _activeCtrl = null;
                  setState(() {
                    _tdsPaid = _parseCtrl(_tdsCtrl, _tdsMax);
                    _syncCtrl(_tdsCtrl, _tdsPaid);
                  });
                }
              },
              hint: 'Up to ${_fmt(_tdsMax)}',
            ),
            const SizedBox(height: 28),

            // ── Calculate button ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculating ? null : _calculate,
                icon: _calculating
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.calculate_rounded),
                label: Text(
                    _calculating ? 'Calculating…' : 'Calculate Tax'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            if (_hasResult && _result != null) ...[
              const SizedBox(height: 28),
              _buildResults(),
            ],
          ],
        ),
      ),
    );
  }

  // ── RESULTS ───────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final newRegime = _result!['newRegime'] as Map<String, dynamic>;
    final oldRegime = _result!['oldRegime'] as Map<String, dynamic>;
    final savings = _result!['savings'] as Map<String, dynamic>;
    final refund = _result!['refund'] as Map<String, dynamic>;
    final cta = _result!['cta'] as String? ?? '';

    final newTax = (newRegime['taxLiability'] as num).toDouble();
    final oldTax = (oldRegime['taxLiability'] as num).toDouble();
    final newNet = (newRegime['netIncome'] as num).toDouble();
    final oldNet = (oldRegime['netIncome'] as num).toDouble();
    final savingsAmt = (savings['amount'] as num).toDouble();
    final savingsRegime = savings['regime'] as String;
    final refundAmt = (refund['amount'] as num).toDouble();
    final refundType = refund['type'] as String;
    final isNewBetter = savingsRegime == 'new';

    final ageLabel = _ageCategory == 'general'
        ? 'Not a senior citizen'
        : _ageCategory == 'senior'
        ? 'Senior citizen (60–79)'
        : 'Super senior citizen (80+)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tax comparison card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border:
            Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _netIncomeChip(
                          label: 'Net income under new', value: newNet)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _netIncomeChip(
                          label: 'Net income under old', value: oldNet)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _taxChip(
                          label: 'New regime',
                          value: newTax,
                          highlight: isNewBetter)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _taxChip(
                          label: 'Old regime\n$ageLabel',
                          value: oldTax,
                          highlight: !isNewBetter)),
                ],
              ),
              if (savingsAmt > 0) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          color: Color(0xFF2E7D32), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You save ${_fmtFull(savingsAmt)} under the '
                              '${savingsRegime == 'new' ? 'New' : 'Old'} Regime',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Refund card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border:
            Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated Refund / Payment',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _refundChip(
                      label: refundType == 'refund'
                          ? 'Your Refund'
                          : refundType == 'payable'
                          ? 'Tax Payable'
                          : 'Nil',
                      value: refundAmt,
                      isRefund: refundType == 'refund',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _refundChip(
                      label: 'TDS Already Paid',
                      value: _tdsPaid,
                      isRefund: true,
                      muted: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CTA
        if (cta.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cta,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  // ── WIDGET HELPERS ────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 13.5,
      color: AppColors.textDark,
    ),
  );

  /// Financial Year selector — fully dynamic from API
  Widget _fySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _availableYears.map((year) {
          final selected = _selectedYear == year;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                if (_selectedYear != year) {
                  setState(() {
                    _selectedYear = year;
                    _hasResult = false;
                    _result = null;
                  });
                  _loadConfig(year);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color:
                  selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                child: Text(
                  year,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color:
                    selected ? Colors.white : AppColors.textMid,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _personaSelector() {
    const options = [
      ('salaried', 'Salaried'),
      ('freelancer', 'Freelancer'),
      ('business', 'Business'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: options.map((opt) {
        final selected = _filingPersona == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _filingPersona = opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: selected ? Colors.white : AppColors.textMid,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _ageSelector() {
    const options = [
      ('general', 'General (< 60)'),
      ('senior', 'Senior (60–79)'),
      ('super_senior', 'Super Senior (80+)'),
    ];
    return Column(
      children: options.map((opt) {
        final selected = _ageCategory == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _ageCategory = opt.$1),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryLight
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                selected ? AppColors.primary : AppColors.divider,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.divider,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                      size: 11, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  opt.$2,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    fontSize: 13,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textMid,
                  ),
                ),
                if (opt.$1 == 'general') ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sliderInput({
    required String label,
    required double value,
    required double max,
    required TextEditingController ctrl,
    required ValueChanged<double> onSliderChanged,
    required ValueChanged<double> onTextChanged,
    required ValueChanged<bool> onFocusChange,
    required String hint,
    bool bold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: Focus(
                onFocusChange: onFocusChange,
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹',
                    prefixStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val) ?? 0;
                    onTextChanged(parsed);
                  },
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primaryLight,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.12),
            trackHeight: 4,
            thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(0, max),
            min: 0,
            max: max,
            divisions: 200,
            onChanged: onSliderChanged,
          ),
        ),
        Text(
          hint,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _netIncomeChip(
      {required String label, required double value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(_fmtFull(value),
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20))),
      ],
    );
  }

  Widget _taxChip({
    required String label,
    required double value,
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withOpacity(0.7)
            : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? const Color(0xFF2E7D32)
              : Colors.transparent,
          width: highlight ? 1.5 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF388E3C),
                  height: 1.4)),
          const SizedBox(height: 4),
          Text(_fmtFull(value),
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: highlight
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF2E7D32))),
          if (highlight)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Better for you',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _refundChip({
    required String label,
    required double value,
    required bool isRefund,
    bool muted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: muted
            ? Colors.white.withOpacity(0.35)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  color: muted
                      ? const Color(0xFF388E3C)
                      : const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(_fmtFull(value),
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: muted
                      ? const Color(0xFF388E3C)
                      : const Color(0xFF1B5E20))),
        ],
      ),
    );
  }
}