import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/document_service.dart';
class StartFilingScreen extends StatefulWidget {
  const StartFilingScreen({super.key});

  @override
  State<StartFilingScreen> createState() => _StartFilingScreenState();
}

class _StartFilingScreenState extends State<StartFilingScreen> {
  final _nameCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isLoading = false;
  bool _panVerified = false;

  String _panName = '';

  final List<Map<String, dynamic>> _uploadedDocs = [];

  final ImagePicker _picker = ImagePicker();

  void _verifyPan() {
    if (_panCtrl.text.length < 10) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _panVerified = true;
        _panName = _nameCtrl.text.isEmpty
            ? 'PAN VERIFIED'
            : _nameCtrl.text.toUpperCase();
      });
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1998),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _dobCtrl.text =
      '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  Future<void> _pickDocument(String documentType) async {

    final response =
    await DocumentService.uploadDocument();

    if (response == null) {
      return;
    }

    final document = response["document"];

    setState(() {

      _uploadedDocs.add({
        "name": document["document_name"],
        "type": documentType,
        "size": document["mime_type"],
        "url": document["file_url"],
      });

    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$documentType uploaded successfully'),
      ),
    );
  }

  Future<void> _captureDocument(String documentType) async {
    final result =
    await DocumentService.uploadFromCamera();

    if (result != null) {

      final document = result['document'];

      setState(() {

        _uploadedDocs.add({
          "type": documentType,
          "name": document['document_name'],
          "size": "Uploaded",
        });

      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Camera upload successful"),
        ),
      );
    }
  }

  void _submitFiling() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Filing request submitted successfully',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _panCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        title: const Text(
          'Start Filing',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        leading: const BackButton(
          color: AppColors.textDark,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 650,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  /// HEADER
                  const Text(
                    'File Your Tax Return',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Upload documents and our tax experts will handle the rest.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textMid,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// PERSONAL DETAILS
                  _sectionCard(
                    title: 'Personal Details',
                    child: Column(
                      children: [

                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _panCtrl,
                          maxLength: 10,
                          textCapitalization:
                          TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Z0-9]'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v.length == 10) {
                              _verifyPan();
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'PAN Number',
                            hintText: 'ABCDE1234F',
                            counterText: '',
                            prefixIcon: Icon(
                              Icons.credit_card_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (_panVerified)
                          Container(
                            width: double.infinity,
                            padding:
                            const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.accent
                                  .withOpacity(0.12),
                              borderRadius:
                              BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.accent,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    _panName,
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight.w700,
                                      fontFamily:
                                      'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _dobCtrl,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            hintText: 'DD/MM/YYYY',
                            prefixIcon: Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// CONTACT DETAILS
                  _sectionCard(
                    title: 'Contact Details',
                    child: Column(
                      children: [

                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType:
                          TextInputType.phone,
                          decoration:
                          const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(
                              Icons.phone_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType:
                          TextInputType.emailAddress,
                          decoration:
                          const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(
                              Icons.email_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// DOCUMENTS
                  _sectionCard(
                    title: 'Upload Documents',
                    child: Column(
                      children: [

                        _documentUploadCard(
                          title: 'Aadhaar Card',
                        ),

                        const SizedBox(height: 16),

                        _documentUploadCard(
                          title: 'PAN Card',
                        ),

                        const SizedBox(height: 16),

                        _documentUploadCard(
                          title: 'Form 16',
                        ),

                        const SizedBox(height: 16),

                        _documentUploadCard(
                          title: 'Bank Statement',
                        ),

                        const SizedBox(height: 16),

                        _documentUploadCard(
                          title: 'Other Documents',
                        ),

                        if (_uploadedDocs.isNotEmpty) ...[
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
                                fontFamily: 'Poppins',
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
                              decoration: BoxDecoration(
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
                                    const EdgeInsets
                                        .all(10),
                                    decoration:
                                    BoxDecoration(
                                      color: Colors.red
                                          .withOpacity(
                                          0.1),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                          12),
                                    ),
                                    child: const Icon(
                                      Icons
                                          .picture_as_pdf_rounded,
                                      color:
                                      Colors.red,
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          doc["name"],
                                          style:
                                          const TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .w700,
                                            fontFamily:
                                            'Poppins',
                                          ),
                                        ),

                                        const SizedBox(
                                            height: 4),

                                        Text(
                                          '${doc["type"]} • ${doc["size"]}',
                                          style:
                                          const TextStyle(
                                            color: AppColors
                                                .textMid,
                                            fontSize: 12,
                                            fontFamily:
                                            'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Icon(
                                    Icons
                                        .check_circle_rounded,
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

                  /// NOTES
                  _sectionCard(
                    title: 'Additional Notes',
                    child: TextFormField(
                      controller: _notesCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                        'Freelancer income, crypto income, GST help, business filings, etc.',
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// SUBMIT
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Submit Filing Request',
                      onTap: _submitFiling,
                      isLoading: _isLoading,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }

  Widget _documentUploadCard({
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [

          Row(
            children: [

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _pickDocument(title),
                  icon: const Icon(
                    Icons.folder_open_rounded,
                  ),
                  label: const Text(
                    'Choose File',
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _captureDocument(title),
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                  ),
                  label: const Text(
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