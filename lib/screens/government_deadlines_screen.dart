import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GovernmentDeadlinesScreen extends StatelessWidget {
  const GovernmentDeadlinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          "Government Deadlines",
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // HERO CARD

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),

                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: const Column(
                children: [

                  Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 54,
                  ),

                  SizedBox(height: 14),

                  Text(
                    "Important Tax Deadlines",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Keep track of important government tax dates to avoid penalties and late filing charges.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _deadlineTile(
              date: "31 July 2026",
              title: "ITR Filing Deadline",
              color: AppColors.statusPending,
            ),

            _deadlineTile(
              date: "15 September 2026",
              title: "Advance Tax Payment",
              color: AppColors.statusReview,
            ),

            _deadlineTile(
              date: "15 December 2026",
              title: "Advance Tax Payment",
              color: AppColors.statusReview,
            ),

            _deadlineTile(
              date: "15 March 2027",
              title: "Advance Tax Payment",
              color: AppColors.statusReview,
            ),

            _deadlineTile(
              date: "31 March 2027",
              title: "Financial Year Closing",
              color: AppColors.statusDone,
            ),
          ],
        ),
      ),
    );
  }
}

class _deadlineTile extends StatelessWidget {
  final String date;
  final String title;
  final Color color;

  const _deadlineTile({
    required this.date,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: AppColors.divider,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [

          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              Icons.event_rounded,
              color: color,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMid,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),

            child: Text(
              "Important",
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}