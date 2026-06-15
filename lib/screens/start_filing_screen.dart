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
  State<StartFilingScreen> createState() => _StartFilingScreenState();
}

class _StartFilingScreenState extends State<StartFilingScreen> {
  bool _isLoading     = false;
  bool _isPickingFile = false;
  bool _isPasswordObscured = true; // Tracks password visibility toggle
  double _uploadProgress = 0;

  final List<Map<String, dynamic>> _uploadedDocs = [];

  // ─── Parse DOB from any format the backend returns ───────────────────────────
  // Handles: "1990-03-01T00:00:00.000Z", "1990-03-01", "01-03-1990", "N/A", null
  String _parseDob(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) return "N/A";
    final s = raw.toString().trim();

    // ISO timestamp: 1990-03-01T00:00:00.000Z
    if (s.contains('T')) {
      try {
        final dt = DateTime.parse(s).toLocal();
        return "${dt.day.toString().padLeft(2,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.year}";
      } catch (_) {}
    }

    // Already YYYY-MM-DD
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
      final parts = s.split('-');
      return "${parts[2]}-${parts[1]}-${parts[0]}"; // flip to DD-MM-YYYY for display
    }

    // Already DD-MM-YYYY — display as-is
    if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(s)) return s;

    return s; // fallback: show whatever is there
  }

  // ─── Pick from storage ────────────────────────────────────────────────────────

  Future<void> _pickDocument(String documentType) async {
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null) return;

      final file = result.files.single;
      setState(() {
        _uploadedDocs.add({
          "type"    : documentType,
          "name"    : file.name,
          "path"    : file.path,
          "size"    : "${(file.size / 1024).toStringAsFixed(1)} KB",
          "uploaded": false,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$documentType selected")),
      );
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  // ─── Capture from camera ──────────────────────────────────────────────────────

  Future<void> _captureDocument(String documentType) async {
    setState(() => _isPickingFile = true);
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return;

      setState(() {
        _uploadedDocs.add({
          "type"    : documentType,
          "name"    : image.name,
          "path"    : image.path,
          "size"    : "Camera Image",
          "uploaded": false,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image captured successfully")),
      );
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  // ─── Delete queued doc ────────────────────────────────────────────────────────

  void _deleteDoc(int index) => setState(() => _uploadedDocs.removeAt(index));

  // ─── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submitFiling() async {
    if (_isLoading) return;

    if (_uploadedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload at least one document")),
      );
      return;
    }

    try {
      setState(() {
        _isLoading      = true;
        _uploadProgress = 0;
      });

      final filingResponse = await FilingService.createFiling(
        filingType    : "ITR Filing",
        assessmentYear: "2025-2026",
        notes         : "",
        memberId      : widget.member["id"].toString(),
      );

      if (filingResponse == null || filingResponse["filing"] == null) {
        throw Exception("Failed to create filing");
      }

      final filingId = filingResponse["filing"]["id"].toString();

      for (int i = 0; i < _uploadedDocs.length; i++) {
        final doc = _uploadedDocs[i];

        await DocumentService.uploadDocumentDirect(
          filingId    : filingId,
          documentType: doc["type"],
          filePath    : doc["path"],
          fileName    : doc["name"],
          onSendProgress: (sent, total) {
            if (mounted) {
              setState(() {
                _uploadProgress = (i + (sent / total)) / _uploadedDocs.length;
              });
            }
          },
        );

        if (mounted) setState(() => _uploadedDocs[i]["uploaded"] = true);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Filing submitted successfully")),
      );
      Navigator.pop(context);

    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Submission failed. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Determine the password value or show N/A if empty/null
    final rawPassword = widget.member["income_tax_password"];
    final hasPassword = rawPassword != null && rawPassword.toString().trim().isNotEmpty;
    final displayPassword = hasPassword ? rawPassword.toString().trim() : "N/A";

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            elevation      : 0,
            backgroundColor: AppColors.background,
            title: const Text(
              'Start Filing',
              style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            ),
            leading: const BackButton(color: AppColors.textDark),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'File Your Tax Return',
                        style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800,
                          color: AppColors.textDark, fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload documents and our tax experts will handle the rest.',
                        style: TextStyle(fontSize: 15, color: AppColors.textMid, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 28),

                      // ── Member details card ──────────────────────────────────
                      _sectionCard(
                        title: 'Selected Member',
                        child: Column(
                          children: [
                            _memberTile(icon: Icons.person_rounded,      label: 'Full Name',    value: widget.member["full_name"]    ?? "N/A"),
                            const SizedBox(height: 14),
                            _memberTile(icon: Icons.credit_card_rounded, label: 'PAN Number',   value: widget.member["pan_number"]   ?? "N/A"),
                            const SizedBox(height: 14),
                            _memberTile(icon: Icons.phone_rounded,       label: 'Phone Number', value: widget.member["phone"]        ?? "N/A"),
                            const SizedBox(height: 14),
                            _memberTile(icon: Icons.email_rounded,       label: 'Email Address',value: widget.member["email"]        ?? "N/A"),
                            const SizedBox(height: 14),
                            _memberTile(icon: Icons.people_alt_rounded,  label: 'Relationship', value: widget.member["relationship"] ?? "N/A"),
                            const SizedBox(height: 14),
                            // ── DOB: parsed cleanly from ISO or any format ────
                            _memberTile(
                              icon : Icons.cake_rounded,
                              label: 'Date of Birth',
                              value: _parseDob(widget.member["date_of_birth"]),
                            ),
                            const SizedBox(height: 14),

                            // ── Always Display Password Tile ─────────────────
                            _memberTile(
                              icon: Icons.lock_rounded,
                              label: 'Password (Income Tax Portal)',
                              value: !hasPassword
                                  ? 'N/A'
                                  : (_isPasswordObscured ? '••••••••' : displayPassword),
                              // Only show the look/hide eye icon button if a password actually exists
                              trailing: hasPassword
                                  ? IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  _isPasswordObscured
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.textMid,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordObscured = !_isPasswordObscured;
                                  });
                                },
                              )
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Upload documents ─────────────────────────────────────
                      _sectionCard(
                        title: 'Upload Documents',
                        child: Column(
                          children: [
                            _documentUploadCard(title: 'Form 16'),
                            const SizedBox(height: 16),
                            _documentUploadCard(title: 'PAN Card'),
                            const SizedBox(height: 16),
                            _documentUploadCard(
                              title   : 'Other Documents',
                              subtitle: 'Aadhaar, Bank Statement, etc.',
                            ),

                            // ── Uploaded files list ──────────────────────────
                            if (_uploadedDocs.isNotEmpty) ...[
                              const SizedBox(height: 26),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Uploaded Files',
                                  style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...List.generate(_uploadedDocs.length, (index) {
                                final doc      = _uploadedDocs[index];
                                final uploaded = doc["uploaded"] == true;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color       : AppColors.background,
                                    borderRadius: BorderRadius.circular(16),
                                    border      : Border.all(
                                      color: uploaded ? Colors.green.withOpacity(0.4) : AppColors.divider,
                                      width: uploaded ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color       : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc["name"],
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${doc["type"]} • ${doc["size"]}',
                                              style: const TextStyle(color: AppColors.textMid, fontSize: 12, fontFamily: 'Poppins'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Green tick after upload
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: uploaded ? Colors.green : AppColors.divider,
                                      ),
                                      const SizedBox(width: 6),
                                      // Delete button
                                      GestureDetector(
                                        onTap: () => _deleteDoc(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color       : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label    : 'Submit Filing Request',
                          onTap    : _submitFiling,
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
        ),

        if (_isLoading || _isPickingFile)
          Container(
            color: Colors.black.withOpacity(0.25),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: _isLoading && _uploadProgress > 0 ? _uploadProgress : null,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoading && _uploadProgress > 0
                        ? "Uploading ${(_uploadProgress * 100).toStringAsFixed(0)}%..."
                        : "Please wait...",
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins', color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width  : double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color       : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border      : Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: AppColors.textDark)),
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
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color       : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border      : Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMid, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Poppins')),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _documentUploadCard({required String title, String? subtitle}) {
    final hasFile = _uploadedDocs.any((d) => d["type"] == title);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color       : hasFile ? Colors.green.withOpacity(0.06) : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border      : Border.all(
          color: hasFile ? Colors.green.withOpacity(0.35) : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Icon(
                  hasFile ? Icons.check_circle_rounded : Icons.description_rounded,
                  color: hasFile ? Colors.green : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: AppColors.textDark)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMid, fontFamily: 'Poppins')),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, constraints) {
            final chooseBtn = Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDocument(title),
                icon : const Icon(Icons.folder_open_rounded),
                label: const FittedBox(child: Text('Choose File')),
              ),
            );
            final cameraBtn = Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _captureDocument(title),
                icon : const Icon(Icons.camera_alt_rounded),
                label: const FittedBox(child: Text('Use Camera')),
              ),
            );
            if (constraints.maxWidth < 340) {
              return Column(children: [
                SizedBox(width: double.infinity, child: chooseBtn),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: cameraBtn),
              ]);
            }
            return Row(children: [chooseBtn, const SizedBox(width: 12), cameraBtn]);
          }),
        ],
      ),
    );
  }
}
