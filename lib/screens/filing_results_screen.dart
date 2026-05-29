import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/filing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class FilingResultsScreen extends StatefulWidget {

  const FilingResultsScreen({super.key});

  @override
  State<FilingResultsScreen> createState() =>
      _FilingResultsScreenState();
}

class _FilingResultsScreenState
    extends State<FilingResultsScreen> {

  bool loading = true;

  List<dynamic> results = [];

  @override
  void initState() {

    super.initState();

    loadResults();
  }

  Future<void> loadResults() async {

    setState(() {
      loading = true;
    });

    final data =
    await FilingService
        .getCustomerFilingResults();

    if (!mounted) return;

    setState(() {

      results = data;

      loading = false;
    });
  }

  Future<void> openFile(String url) async {

    try {

      print("OPENING URL: $url");

      final Uri uri = Uri.parse(url);

      final bool launched =
      await launchUrl(

        uri,

        mode:
        LaunchMode.externalApplication,
      );

      print("LAUNCHED: $launched");

      if (!launched) {

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Could not open file",
            ),
          ),
        );
      }

    } catch (e) {

      print("OPEN FILE ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content: Text(
            "Error opening file: $e",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      AppColors.background,

      appBar: AppBar(

        title: const Text(
          "Filing Results",
        ),
      ),

      body: loading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : results.isEmpty

          ? Center(

        child: Column(

          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            Icon(

              Icons.description_outlined,

              size: 64,

              color:
              AppColors.textLight,
            ),

            const SizedBox(height: 14),

            const Text(

              "No filing results available",

              style: TextStyle(

                fontSize: 15,

                color:
                AppColors.textLight,

                fontFamily:
                'Poppins',
              ),
            ),
          ],
        ),
      )

          : RefreshIndicator(

        onRefresh: loadResults,

        child: ListView.builder(

          padding:
          const EdgeInsets.all(18),

          itemCount:
          results.length,

          itemBuilder:
              (context, index) {

            final item =
            results[index];

            return Container(

              margin:
              const EdgeInsets.only(
                bottom: 16,
              ),

              padding:
              const EdgeInsets.all(18),

              decoration: BoxDecoration(

                color:
                AppColors.cardBg,

                borderRadius:
                BorderRadius.circular(18),

                border: Border.all(
                  color:
                  AppColors.divider,
                ),

                boxShadow: [

                  BoxShadow(

                    color:
                    Colors.black.withOpacity(0.04),

                    blurRadius: 10,

                    offset:
                    const Offset(0, 4),
                  ),
                ],
              ),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      Expanded(

                        child: Text(

                          item['filing_type']
                              ?? "ITR Filing",

                          style:
                          const TextStyle(

                            fontSize: 16,

                            fontWeight:
                            FontWeight.w700,

                            fontFamily:
                            'Poppins',

                            color:
                            AppColors.textDark,
                          ),
                        ),
                      ),

                      StatusBadge(
                        item['status'] ?? "Completed",
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(

                    item['member_name']
                        ?? "Member",

                    style:
                    const TextStyle(

                      fontSize: 13,

                      fontWeight:
                      FontWeight.w600,

                      color:
                      AppColors.textMid,

                      fontFamily:
                      'Poppins',
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(

                    "Assessment Year: ${item['assessment_year']}",

                    style:
                    const TextStyle(

                      fontSize: 12,

                      color:
                      AppColors.textLight,

                      fontFamily:
                      'Poppins',
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(

                    width: double.infinity,

                    padding:
                    const EdgeInsets.all(14),

                    decoration: BoxDecoration(

                      color:
                      AppColors.primaryLight,

                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),

                    child: Row(

                      children: [

                        const Icon(

                          Icons
                              .description_rounded,

                          color:
                          AppColors.primary,
                        ),

                        const SizedBox(width: 12),

                        Expanded(

                          child: Text(

                            item['file_name']
                                ?? "Result File",

                            style:
                            const TextStyle(

                              fontFamily:
                              'Poppins',

                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),

                        ElevatedButton.icon(

                          onPressed: () {

                            final fileUrl =
                            item['file_url'];

                            if (
                            fileUrl != null &&
                                fileUrl.toString().isNotEmpty
                            ) {

                              openFile(fileUrl);
                            }
                          },

                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                          ),

                          label: const Text(
                            "Open",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}