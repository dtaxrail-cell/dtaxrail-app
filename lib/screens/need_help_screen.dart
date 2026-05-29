import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/callback_service.dart';

class NeedHelpScreen extends StatefulWidget {
  const NeedHelpScreen({super.key});

  @override
  State<NeedHelpScreen> createState() => _NeedHelpScreenState();
}

class _NeedHelpScreenState extends State<NeedHelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  int _expandedFaq = -1;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _issueCtrl = TextEditingController();

  bool _submitted = false;

  static const _faqs = [
    (
    'What is the deadline for filing ITR for FY 2024-25?',
    'The last date to file income tax return (ITR) for FY 2024-25 (AY 2025-26) for non-audit cases is July 31, 2025.'
    ),
    (
    'How do I check my refund status?',
    'You can check your ITR refund status on the Income Tax e-filing portal at incometax.gov.in, or through the NSDL website using your PAN and assessment year.'
    ),
    (
    'What documents do I need for ITR filing?',
    'Typically you need Form 16 (from employer), bank statements, investment proofs (80C/80D), PAN card, and Aadhaar card. Our experts will guide you based on your profile.'
    ),
    (
    'How long does it take to file my return?',
    'Once we receive your documents, our team typically reviews and files within 24-48 working hours. You will receive updates at each step.'
    ),
    (
    'Will you help if I receive an income tax notice?',
    'Yes! We provide free resolution of income tax notices if your ITR was filed through us. Our experts will prepare and file responses on your behalf.'
    ),
    (
    'What is the difference between old and new tax regime?',
    'The old regime allows various deductions (80C, HRA, etc.) while the new regime offers lower slab rates but fewer deductions. Use our Tax Tools calculator to compare which is better for you.'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _issueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Need Help?'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'FAQs'),
            Tab(text: 'Request Callback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildFaq(),
          _buildCallback(),
        ],
      ),
    );
  }

  Widget _buildFaq() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      itemCount: _faqs.length,
      itemBuilder: (ctx, i) {
        final idx = i;
        final (q, a) = _faqs[idx];

        final isOpen = _expandedFaq == idx;

        return GestureDetector(
        onTap: () =>
        setState(() => _expandedFaq = isOpen ? -1 : idx),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
        color: isOpen
        ? AppColors.primaryLight
            : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
        color: isOpen
        ? AppColors.primary.withOpacity(0.3)
            : AppColors.divider,
        ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
        children: [
        Expanded(
        child: Text(
        q,
        style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isOpen
        ? AppColors.primary
            : AppColors.textDark,
        fontFamily: 'Poppins',
        ),
        ),
        ),
        Icon(
        isOpen
        ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded,
        color: AppColors.primary,
        ),
        ],
        ),
        ),
        if (isOpen)
        Padding(
        padding:
        const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Text(
        a,
        style: const TextStyle(
        fontSize: 12.5,
        color: AppColors.textMid,
        fontFamily: 'Poppins',
        height: 1.6,
        ),
        ),
        ),
        ],
        ),
        ),
        );
      },
    );

  }

  Widget _buildCallback() {
    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_callback_rounded,
                  color: AppColors.accent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Callback Request Submitted!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our expert will contact you shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMid,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const SectionTitle('Request a Callback'),

    const SizedBox(height: 6),

    const Text(
    'Our tax expert will contact you shortly after receiving your request',
    style: TextStyle(
    fontSize: 13,
    color: AppColors.textMid,
    fontFamily: 'Poppins',
    ),
    ),

    const SizedBox(height: 24),

    TextFormField(
    controller: _nameCtrl,
    decoration: const InputDecoration(
    hintText: 'Your name',
    labelText: 'Full Name',
    prefixIcon: Icon(
    Icons.person_outline_rounded,
    color: AppColors.primary,
    ),
    ),
    ),

    const SizedBox(height: 14),

    TextFormField(
    controller: _phoneCtrl,
    keyboardType: TextInputType.phone,
    decoration: const InputDecoration(
    hintText: '10-digit mobile number',
    labelText: 'Mobile Number',
    prefixText: '+91  ',
    prefixIcon: Icon(
    Icons.phone_outlined,
    color: AppColors.primary,
    ),
    ),
    ),

      const SizedBox(height: 14),

      TextFormField(
        controller: _issueCtrl,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Describe your issue',
          hintText: 'Tell us how we can help',
          prefixIcon: Icon(
            Icons.help_outline,
            color: AppColors.primary,
          ),
        ),
      ),

      const SizedBox(height: 28),
    const SizedBox(height: 28),

      PrimaryButton(
        label: 'Request Callback',
        icon: Icons.phone_in_talk_rounded,
        onTap: () async {
          if (_nameCtrl.text.trim().isEmpty ||
              _phoneCtrl.text.trim().isEmpty ||
              _issueCtrl.text.trim().isEmpty) {

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Fill all fields',
                ),
              ),
            );

            return;
          }

          if (_phoneCtrl.text.trim().length != 10) {

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Mobile number must be 10 digits',
                ),
              ),
            );

            return;
          }

          final success =
          await CallbackService
              .requestCallback(
            phone:
            _phoneCtrl.text.trim(),
            issue:
            _issueCtrl.text.trim(),
          );

          if (success) {
            setState(() {
              _submitted = true;
            });
          } else {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to submit',
                ),
              ),
            );
          }
        },
      ),
    ],
    ),
    );

  }
}
