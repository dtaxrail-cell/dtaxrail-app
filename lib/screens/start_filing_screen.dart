import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/document_service.dart';
import '../services/filing_service.dart';

class StartFilingScreen extends StatefulWidget {

  final Map<String, dynamic> member;

  const StartFilingScreen({
    super.key,
    required this.member,
  });

  @override
  State<StartFilingScreen> createState() =>
      _StartFilingScreenState();
}

class _StartFilingScreenState
    extends State<StartFilingScreen> {

  final _notesCtrl = TextEditingController();

  bool _isLoading = false;

  bool _isPickingFile = false;

  double _uploadProgress = 0;

  final List<Map<String, dynamic>>
  _uploadedDocs = [];

  Future<void> _pickDocument(
      String documentType,
      ) async {

    setState(() {
      _isPickingFile = true;
    });

    try {

      FilePickerResult? result =
      await FilePicker.pickFiles(

        type: FileType.custom,

        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
        ],
      );

      if (result == null) {
        return;
      }

      final file =
          result.files.single;

      setState(() {

        _uploadedDocs.add({

          "type": documentType,

          "name": file.name,

          "path": file.path,

          "size":
          "${(file.size / 1024).toStringAsFixed(1)} KB",
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          content: Text(
            "$documentType selected",
          ),
        ),
      );

    } catch (e) {

      print(e);

    } finally {

      if (mounted) {

        setState(() {
          _isPickingFile = false;
        });
      }
    }
  }

  Future<void> _captureDocument(
      String documentType,
      ) async {

    setState(() {
      _isPickingFile = true;
    });

    try {

      final ImagePicker picker =
      ImagePicker();

      final XFile? image =
      await picker.pickImage(
        source: ImageSource.camera,
      );

      if (image == null) {
        return;
      }

      setState(() {

        _uploadedDocs.add({

          "type": documentType,

          "name": image.name,

          "path": image.path,

          "size": "Camera Image",
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Image captured successfully",
          ),
        ),
      );

    } catch (e) {

      print(e);

    } finally {

      if (mounted) {

        setState(() {
          _isPickingFile = false;
        });
      }
    }
  }

  Future<void> _submitFiling() async {

    if (_isLoading) {
      return;
    }

    try {

      if (_uploadedDocs.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(
            content: Text(
              "Please upload at least one document",
            ),
          ),
        );

        return;
      }

      setState(() {

        _isLoading = true;

        _uploadProgress = 0;
      });

      final filingResponse =
      await FilingService.createFiling(

        filingType: "ITR Filing",

        assessmentYear: "2025-2026",

        notes: _notesCtrl.text,

        memberId:
        widget.member["id"].toString(),
      );

      if (
      filingResponse == null ||
          filingResponse["filing"] == null
      ) {

        throw Exception(
          "Failed to create filing",
        );
      }

      final filingId =
      filingResponse["filing"]["id"]
          .toString();

      for (int i = 0; i < _uploadedDocs.length; i++) {

        final doc = _uploadedDocs[i];

        await DocumentService.uploadDocumentDirect(

          filingId: filingId,

          documentType: doc["type"],

          filePath: doc["path"],

          fileName: doc["name"],

          onSendProgress: (sent, total) {

            if (mounted) {

              setState(() {

                _uploadProgress =
                    (i + (sent / total)) /
                        _uploadedDocs.length;
              });
            }
          },
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Filing submitted successfully",
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      print(e);

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Submission failed",
          ),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {

          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {

    _notesCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Stack(

      children: [

        Scaffold(

            backgroundColor:
            AppColors.background,

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
        AppColors.background,

        title: const Text(

          'Start Filing',

          style: TextStyle(

            fontWeight:
            FontWeight.w700,

            fontFamily:
            'Poppins',
          ),
        ),

        leading: const BackButton(
          color: AppColors.textDark,
        ),
      ),

      body: SafeArea(

        child: SingleChildScrollView(

          padding:
          const EdgeInsets.all(20),

          child: Center(

            child: ConstrainedBox(

              constraints:
              const BoxConstraints(
                maxWidth: 650,
              ),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const Text(

                    'File Your Tax Return',

                    style: TextStyle(

                      fontSize: 28,

                      fontWeight:
                      FontWeight.w800,

                      color:
                      AppColors.textDark,

                      fontFamily:
                      'Poppins',
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(

                    'Upload documents and our tax experts will handle the rest.',

                    style: TextStyle(

                      fontSize: 15,

                      color:
                      AppColors.textMid,

                      fontFamily:
                      'Poppins',
                    ),
                  ),

                  const SizedBox(height: 28),

                  _sectionCard(

                    title:
                    'Selected Member',

                    child: Column(

                      children: [

                        _memberTile(

                          icon:
                          Icons.person_rounded,

                          label:
                          'Full Name',

                          value:
                          widget.member["full_name"]
                              ?? "N/A",
                        ),

                        const SizedBox(height: 14),

                        _memberTile(

                          icon:
                          Icons.credit_card_rounded,

                          label:
                          'PAN Number',

                          value:
                          widget.member["pan_number"]
                              ?? "N/A",
                        ),

                        const SizedBox(height: 14),

                        _memberTile(

                          icon:
                          Icons.phone_rounded,

                          label:
                          'Phone Number',

                          value:
                          widget.member["phone"]
                              ?? "N/A",
                        ),

                        const SizedBox(height: 14),

                        _memberTile(

                          icon:
                          Icons.email_rounded,

                          label:
                          'Email Address',

                          value:
                          widget.member["email"]
                              ?? "N/A",
                        ),

                        const SizedBox(height: 14),

                        _memberTile(

                          icon:
                          Icons.people_alt_rounded,

                          label:
                          'Relationship',

                          value:
                          widget.member["relationship"]
                              ?? "N/A",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  _sectionCard(

                    title:
                    'Upload Documents',

                    child: Column(

                      children: [

                        _documentUploadCard(
                          title:
                          'Aadhaar Card',
                        ),

                        const SizedBox(height: 16),

                        _documentUploadCard(
                          title:
                          'PAN Card',
                        ),

                        const SizedBox(height: 16),

                        _documentUploadCard(
                          title:
                          'Form 16',
                        ),

                        const SizedBox(height: 16),

                        _documentUploadCard(
                          title:
                          'Bank Statement',
                        ),

                        const SizedBox(height: 16),

                        _documentUploadCard(
                          title:
                          'Other Documents',
                        ),

                        if (
                        _uploadedDocs.isNotEmpty
                        ) ...[

                          const SizedBox(height: 26),

                          const Align(

                            alignment:
                            Alignment.centerLeft,

                            child: Text(

                              'Uploaded Files',

                              style: TextStyle(

                                fontSize: 16,

                                fontWeight:
                                FontWeight.w700,

                                fontFamily:
                                'Poppins',
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          ..._uploadedDocs.map(

                                (doc) => Container(

                              margin:
                              const EdgeInsets.only(
                                bottom: 12,
                              ),

                              padding:
                              const EdgeInsets.all(14),

                              decoration:
                              BoxDecoration(

                                color:
                                AppColors.background,

                                borderRadius:
                                BorderRadius.circular(
                                  16,
                                ),

                                border: Border.all(
                                  color:
                                  AppColors.divider,
                                ),
                              ),

                              child: Row(

                                children: [

                                  Container(

                                    padding:
                                    const EdgeInsets.all(10),

                                    decoration:
                                    BoxDecoration(

                                      color:
                                      Colors.red.withOpacity(0.1),

                                      borderRadius:
                                      BorderRadius.circular(
                                        12,
                                      ),
                                    ),

                                    child:
                                    const Icon(

                                      Icons.picture_as_pdf_rounded,

                                      color:
                                      Colors.red,
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  Expanded(

                                    child: Column(

                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                      children: [

                                        Text(

                                          doc["name"],

                                          style:
                                          const TextStyle(

                                            fontWeight:
                                            FontWeight.w700,

                                            fontFamily:
                                            'Poppins',
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(

                                          '${doc["type"]} • ${doc["size"]}',

                                          style:
                                          const TextStyle(

                                            color:
                                            AppColors.textMid,

                                            fontSize: 12,

                                            fontFamily:
                                            'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Icon(

                                    Icons.check_circle_rounded,

                                    color:
                                    AppColors.accent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  _sectionCard(

                    title:
                    'Additional Notes',

                    child: TextFormField(

                      controller:
                      _notesCtrl,

                      maxLines: 4,

                      decoration:
                      const InputDecoration(

                        hintText:
                        'Freelancer income, crypto income, GST help, business filings, etc.',
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(

                    width: double.infinity,

                    child: PrimaryButton(

                      label:
                      'Submit Filing Request',

                      onTap:
                      _submitFiling,

                      isLoading:
                      _isLoading,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
        ),

        if (_isLoading || _isPickingFile)
          Container(
            color: Colors.black.withOpacity(0.25),

            child: const Center(

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  CircularProgressIndicator(),

                  SizedBox(height: 16),

                  Text(

                    "Please wait...",

                    style: TextStyle(

                      fontSize: 15,

                      fontWeight: FontWeight.w500,

                      fontFamily: 'Poppins',

                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionCard({

    required String title,

    required Widget child,

  }) {

    return Container(

      width: double.infinity,

      padding:
      const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color:
        AppColors.surface,

        borderRadius:
        BorderRadius.circular(22),

        border: Border.all(
          color:
          AppColors.divider,
        ),
      ),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(

            title,

            style:
            const TextStyle(

              fontSize: 18,

              fontWeight:
              FontWeight.w700,

              fontFamily:
              'Poppins',

              color:
              AppColors.textDark,
            ),
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }

  Widget _memberTile({

    required IconData icon,

    required String label,

    required String value,

  }) {

    return Container(

      padding:
      const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color:
        AppColors.background,

        borderRadius:
        BorderRadius.circular(16),

        border: Border.all(
          color:
          AppColors.divider,
        ),
      ),

      child: Row(

        children: [

          Container(

            padding:
            const EdgeInsets.all(10),

            decoration: BoxDecoration(

              color:
              AppColors.primaryLight,

              borderRadius:
              BorderRadius.circular(12),
            ),

            child: Icon(

              icon,

              color:
              AppColors.primary,

              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(

                  label,

                  style:
                  const TextStyle(

                    fontSize: 12,

                    color:
                    AppColors.textMid,

                    fontFamily:
                    'Poppins',
                  ),
                ),

                const SizedBox(height: 4),

                Text(

                  value,

                  style:
                  const TextStyle(

                    fontSize: 15,

                    fontWeight:
                    FontWeight.w700,

                    color:
                    AppColors.textDark,

                    fontFamily:
                    'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentUploadCard({

    required String title,

  }) {

    return Container(

      padding:
      const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color:
        AppColors.primaryLight,

        borderRadius:
        BorderRadius.circular(18),

        border: Border.all(

          color:
          AppColors.primary.withOpacity(0.2),
        ),
      ),

      child: Column(

        children: [

          Row(

            children: [

              Container(

                padding:
                const EdgeInsets.all(12),

                decoration:
                BoxDecoration(

                  color:
                  Colors.white,

                  borderRadius:
                  BorderRadius.circular(14),
                ),

                child:
                const Icon(

                  Icons.description_rounded,

                  color:
                  AppColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(

                child: Text(

                  title,

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
            ],
          ),

          const SizedBox(height: 18),

          Row(

            children: [

              Expanded(

                child:
                OutlinedButton.icon(

                  onPressed:
                      () => _pickDocument(title),

                  icon:
                  const Icon(

                    Icons.folder_open_rounded,
                  ),

                  label:
                  const Text(
                    'Choose File',
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(

                child:
                ElevatedButton.icon(

                  onPressed:
                      () => _captureDocument(title),

                  icon:
                  const Icon(

                    Icons.camera_alt_rounded,
                  ),

                  label:
                  const Text(
                    'Use Camera',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}