import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../theme/app_theme.dart';

class GovernmentDeadlinesScreen extends StatefulWidget {
  const GovernmentDeadlinesScreen({super.key});

  @override
  State<GovernmentDeadlinesScreen> createState() => _GovernmentDeadlinesScreenState();
}

class _GovernmentDeadlinesScreenState extends State<GovernmentDeadlinesScreen> {
  final Dio _dio = Dio();
  List<dynamic> _deadlines = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDeadlines();
  }

  Future<void> _fetchDeadlines() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _dio.get('${ApiConfig.baseUrl}/deadlines');

      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _deadlines = response.data['deadlines'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = "Failed to parse updates from server.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error. Please try again later.";
      });
      print("Error fetching deadlines: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Government Deadlines"),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDeadlines,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: Colors.white, size: 54),
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
                        style: TextStyle(color: Colors.white70, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.textMid),
                  ),
                ),
              )
            else if (_deadlines.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      "No upcoming deadlines listed.",
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final item = _deadlines[index];
                        return _DeadlineTile(
                          title: item['title'] ?? 'Tax Deadline',
                          date: _formatDate(item['date']?.toString()),
                          isActive: item['is_active'] ?? true,
                        );
                      },
                      childCount: _deadlines.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  final String date;
  final String title;
  final bool isActive;

  const _DeadlineTile({
    required this.date,
    required this.title,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.event_rounded,
              color: isActive ? AppColors.primary : AppColors.textLight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  date,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}