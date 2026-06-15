import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/callback_service.dart';
import '../services/faq_service.dart';

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
  Future<void> _loadFaqs() async {

    final data =
    await FaqService.getFaqs();

    setState(() {

      _faqs = data;

      _loadingFaqs = false;

    });
  }

  bool _submitted = false;

  List<dynamic> _faqs = [];

  bool _loadingFaqs = true;

  @override
  void initState() {
    super.initState();

    _tabCtrl =
        TabController(length: 2, vsync: this);

    _loadFaqs();
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

    if (_loadingFaqs) {

      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      itemCount: _faqs.length,
      itemBuilder: (ctx, i) {
        final idx = i;
        final faq = _faqs[idx];

        final q =
            faq['question'] ?? '';

        final a =
            faq['answer'] ?? '';

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

      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Contact Us Directly",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                fontFamily: 'Poppins',
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Phone",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      SizedBox(height: 2),

                      Text(
                        "8187882772",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.email_rounded,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Email",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      SizedBox(height: 2),

                      Text(
                        "dtaxrail@gmail.com",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),
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
