import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../services/member_service.dart';
import 'start_filing_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  bool _isLoading = true;
  List<dynamic> _members = [];

  static const List<String> _relationships = [
    'Self', 'Mother', 'Father', 'Sister', 'Brother', 'Friend', 'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final members = await MemberService.getMembers();
    if (!mounted) return;
    setState(() {
      _members   = members;
      _isLoading = false;
    });
  }

  // ─── Validators ───────────────────────────────────────────────────────────────

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'Full name is required';
    return null;
  }

  String? _validatePan(String value) {
    final pan = value.trim();
    if (pan.isEmpty) return 'PAN number is required';
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
      return 'Invalid PAN (e.g. ABCDE1234F)';
    }
    return null;
  }

  String? _validatePhone(String value) {
    final phone = value.trim();
    if (phone.isEmpty) return 'Phone number is required';
    if (phone.length != 10) return 'Must be 10 digits';
    return null;
  }

  String? _validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return null;
    if (!RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Invalid email address';
    }
    return null;
  }

  // ─── DOB helpers ──────────────────────────────────────────────────────────────

  /// Display format: DD-MM-YYYY (shown in the text field)
  String _formatDobForDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.year}';

  /// API format: YYYY-MM-DD (sent to backend / stored in Postgres)
  String _formatDobForApi(DateTime d) =>
      '${d.year}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  /// Parse DD-MM-YYYY display string back to DateTime for the date picker
  DateTime? _parseDobDisplay(String text) {
    if (text.isEmpty) return null;
    final parts = text.split('-');
    if (parts.length != 3) return null;
    return DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
  }

  /// Parse YYYY-MM-DD (from backend) to display DD-MM-YYYY string
  String _apiDobToDisplay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final s = raw.trim();
    // YYYY-MM-DD
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
      final parts = s.substring(0, 10).split('-');
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    // Already DD-MM-YYYY — return as-is
    return s;
  }

  // ─── Date picker ──────────────────────────────────────────────────────────────

  Future<void> _pickDate(BuildContext ctx, TextEditingController ctrl) async {
    final initial = _parseDobDisplay(ctrl.text) ?? DateTime(1990);
    final picked  = await showDatePicker(
      context    : ctx,
      initialDate: initial,
      firstDate  : DateTime(1900),
      lastDate   : DateTime.now(),
    );
    if (picked != null) {
      ctrl.text = _formatDobForDisplay(picked);
    }
  }

  // ─── Shared field builders ────────────────────────────────────────────────────

  Widget _buildUpperCaseField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? extraFormatters,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller    : controller,
      keyboardType  : keyboardType,
      inputFormatters: [
        TextInputFormatter.withFunction((o, n) =>
            n.copyWith(text: n.text.toUpperCase(), selection: n.selection)),
        ...?extraFormatters,
      ],
      onChanged  : onChanged,
      decoration : InputDecoration(
        labelText: label,
        errorText: errorText,
        border   : const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext ctx,
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      readOnly  : true,
      onTap     : () => _pickDate(ctx, controller),
      decoration: InputDecoration(
        labelText : label,
        border    : const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today_rounded),
      ),
    );
  }

  Widget _buildRelationshipDropdown({
    required String? value,
    required void Function(String?) onChanged,
    String? errorText,
  }) {
    return DropdownButtonFormField<String>(
      value     : value,
      decoration: InputDecoration(
        labelText: 'Relationship *',
        border   : const OutlineInputBorder(),
        errorText: errorText,
      ),
      items: _relationships
          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
          .toList(),
      onChanged: onChanged,
    );
  }

  /// Optional password field with a show/hide toggle.
  /// Used for the member's income-tax e-filing portal password (optional).
  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscured,
    required VoidCallback onToggleObscure,
  }) {
    return TextField(
      controller : controller,
      obscureText: obscured,
      decoration : InputDecoration(
        labelText  : "Password (if available)",
        helperText : "Optional — e.g. Income Tax e-filing portal password",
        border     : const OutlineInputBorder(),
        suffixIcon : IconButton(
          icon: Icon(obscured
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }

  Widget _buildDialogScrollBody(List<Widget> children) {
    return SizedBox(
      height: 420,
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }

  // ─── Add Member dialog ────────────────────────────────────────────────────────

  Future<void> _showAddMemberDialog() async {
    final nameCtrl     = TextEditingController();
    final panCtrl      = TextEditingController();
    final phoneCtrl    = TextEditingController();
    final emailCtrl    = TextEditingController();
    final dobCtrl      = TextEditingController(); // stores DD-MM-YYYY for display
    final passwordCtrl = TextEditingController();

    String? selectedRelationship;
    String? nameError;
    String? panError;
    String? phoneError;
    String? emailError;
    String? relationshipError;
    bool isSaving = false;
    bool passwordObscured = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Add Member",
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          ),
          content: _buildDialogScrollBody([

            _buildUpperCaseField(
              controller: nameCtrl,
              label     : "Full Name *",
              errorText : nameError,
              onChanged : (v) => setDialogState(() => nameError = _validateName(v)),
            ),
            const SizedBox(height: 14),

            _buildUpperCaseField(
              controller    : panCtrl,
              label         : "PAN Number *",
              errorText     : panError,
              extraFormatters: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              ],
              onChanged: (v) => setDialogState(() => panError = _validatePan(v)),
            ),
            const SizedBox(height: 14),

            TextField(
              controller     : phoneCtrl,
              keyboardType   : TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (v) => setDialogState(() => phoneError = _validatePhone(v)),
              decoration: InputDecoration(
                labelText: "Phone Number *",
                errorText: phoneError,
                border   : const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller  : emailCtrl,
              keyboardType: TextInputType.emailAddress,
              onChanged   : (v) => setDialogState(() => emailError = _validateEmail(v)),
              decoration  : InputDecoration(
                labelText: "Email Address",
                errorText: emailError,
                border   : const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            _buildDateField(ctx: ctx, controller: dobCtrl, label: "Date of Birth"),
            const SizedBox(height: 14),

            _buildRelationshipDropdown(
              value    : selectedRelationship,
              errorText: relationshipError,
              onChanged: (v) => setDialogState(() {
                selectedRelationship = v;
                relationshipError    = null;
              }),
            ),
            const SizedBox(height: 14),

            _buildPasswordField(
              controller     : passwordCtrl,
              obscured       : passwordObscured,
              onToggleObscure: () => setDialogState(() => passwordObscured = !passwordObscured),
            ),

            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("* Required fields", style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child    : const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                final nErr   = _validateName(nameCtrl.text);
                final pErr   = _validatePan(panCtrl.text);
                final phErr  = _validatePhone(phoneCtrl.text);
                final eErr   = _validateEmail(emailCtrl.text);
                final relErr = selectedRelationship == null
                    ? 'Please select a relationship'
                    : null;

                if (nErr != null || pErr != null || phErr != null ||
                    eErr != null || relErr != null) {
                  setDialogState(() {
                    nameError         = nErr;
                    panError          = pErr;
                    phoneError        = phErr;
                    emailError        = eErr;
                    relationshipError = relErr;
                  });
                  return;
                }

                setDialogState(() => isSaving = true);

                // Convert display DOB (DD-MM-YYYY) → API format (YYYY-MM-DD)
                String? apiDob;
                if (dobCtrl.text.trim().isNotEmpty) {
                  final dt = _parseDobDisplay(dobCtrl.text.trim());
                  apiDob = dt != null ? _formatDobForApi(dt) : null;
                }

                final response = await MemberService.createMember(
                  fullName    : nameCtrl.text.trim(),
                  panNumber   : panCtrl.text.trim(),
                  phone       : phoneCtrl.text.trim(),
                  email       : emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  relationship: selectedRelationship!,
                  dateOfBirth : apiDob,
                  incomeTaxPassword: passwordCtrl.text.trim().isEmpty
                      ? null
                      : passwordCtrl.text.trim(),
                );

                if (!mounted) return;
                setDialogState(() => isSaving = false);

                if (response != null) {
                  Navigator.pop(ctx);
                  await _loadMembers();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Member added successfully")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to add member")),
                  );
                }
              },
              child: isSaving
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Operations bottom sheet ──────────────────────────────────────────────────

  void _showOperationsBottomSheet() {
    showModalBottomSheet(
      context        : context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title  : const Text("Edit Member"),
              onTap  : () { Navigator.pop(context); _showMemberSelector(isDelete: false); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title  : const Text("Delete Member", style: TextStyle(color: Colors.red)),
              onTap  : () { Navigator.pop(context); _showMemberSelector(isDelete: true); },
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberSelector({required bool isDelete}) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        shrinkWrap: true,
        itemCount : _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          return ListTile(
            leading : CircleAvatar(child: Text((member["full_name"] ?? "?")[0].toUpperCase())),
            title   : Text(member["full_name"] ?? ""),
            subtitle: Text(member["relationship"] ?? ""),
            onTap   : () {
              Navigator.pop(context);
              isDelete ? _deleteMember(member) : _showEditMemberDialog(member);
            },
          );
        },
      ),
    );
  }

  // ─── Edit Member dialog ───────────────────────────────────────────────────────

  Future<void> _showEditMemberDialog(dynamic member) async {
    final nameCtrl     = TextEditingController(text: member["full_name"]  ?? "");
    final panCtrl      = TextEditingController(text: member["pan_number"] ?? "");
    final phoneCtrl    = TextEditingController(text: member["phone"]      ?? "");
    final emailCtrl    = TextEditingController(text: member["email"]      ?? "");
    final passwordCtrl = TextEditingController(text: member["income_tax_password"] ?? "");
    // Backend stores YYYY-MM-DD — convert to DD-MM-YYYY for display
    final dobCtrl   = TextEditingController(
      text: _apiDobToDisplay(member["date_of_birth"]),
    );

    final savedRel = member["relationship"] ?? "";
    String? selectedRelationship = _relationships.contains(savedRel) ? savedRel : null;

    String? nameError;
    String? panError;
    String? phoneError;
    String? emailError;
    String? relationshipError;
    bool isSaving = false;
    bool passwordObscured = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Edit Member",
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          ),
          content: _buildDialogScrollBody([
            _buildUpperCaseField(
              controller: nameCtrl,
              label     : "Full Name *",
              errorText : nameError,
              onChanged : (v) => setDialogState(() => nameError = _validateName(v)),
            ),
            const SizedBox(height: 12),
            _buildUpperCaseField(
              controller    : panCtrl,
              label         : "PAN Number *",
              errorText     : panError,
              extraFormatters: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              ],
              onChanged: (v) => setDialogState(() => panError = _validatePan(v)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller     : phoneCtrl,
              keyboardType   : TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (v) => setDialogState(() => phoneError = _validatePhone(v)),
              decoration: InputDecoration(
                labelText: "Phone Number *",
                errorText: phoneError,
                border   : const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller  : emailCtrl,
              keyboardType: TextInputType.emailAddress,
              onChanged   : (v) => setDialogState(() => emailError = _validateEmail(v)),
              decoration  : InputDecoration(
                labelText: "Email Address",
                errorText: emailError,
                border   : const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _buildDateField(ctx: ctx, controller: dobCtrl, label: "Date of Birth"),
            const SizedBox(height: 12),
            _buildRelationshipDropdown(
              value    : selectedRelationship,
              errorText: relationshipError,
              onChanged: (v) => setDialogState(() {
                selectedRelationship = v;
                relationshipError    = null;
              }),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller     : passwordCtrl,
              obscured       : passwordObscured,
              onToggleObscure: () => setDialogState(() => passwordObscured = !passwordObscured),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("* Required fields", style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child    : const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                final nErr   = _validateName(nameCtrl.text);
                final pErr   = _validatePan(panCtrl.text);
                final phErr  = _validatePhone(phoneCtrl.text);
                final eErr   = _validateEmail(emailCtrl.text);
                final relErr = selectedRelationship == null
                    ? 'Please select a relationship'
                    : null;

                if (nErr != null || pErr != null || phErr != null ||
                    eErr != null || relErr != null) {
                  setDialogState(() {
                    nameError         = nErr;
                    panError          = pErr;
                    phoneError        = phErr;
                    emailError        = eErr;
                    relationshipError = relErr;
                  });
                  return;
                }

                setDialogState(() => isSaving = true);

                // Convert display DOB (DD-MM-YYYY) → API format (YYYY-MM-DD)
                String? apiDob;
                if (dobCtrl.text.trim().isNotEmpty) {
                  final dt = _parseDobDisplay(dobCtrl.text.trim());
                  apiDob = dt != null ? _formatDobForApi(dt) : null;
                }

                final success = await MemberService.updateMember(
                  memberId    : member["id"].toString(),
                  fullName    : nameCtrl.text.trim(),
                  panNumber   : panCtrl.text.trim(),
                  phone       : phoneCtrl.text.trim(),
                  email       : emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  relationship: selectedRelationship!,
                  dateOfBirth : apiDob,
                  incomeTaxPassword: passwordCtrl.text.trim().isEmpty
                      ? null
                      : passwordCtrl.text.trim(),
                );

                if (!mounted) return;
                setDialogState(() => isSaving = false);

                if (success) {
                  Navigator.pop(ctx);
                  await _loadMembers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Member updated successfully")),
                  );
                }
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete Member ────────────────────────────────────────────────────────────

  Future<void> _deleteMember(dynamic member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text("Delete Member"),
        content: Text("Delete ${member["full_name"]} and all filings?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style    : ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child    : const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await MemberService.deleteMember(member["id"].toString());
    if (success) {
      await _loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Member deleted successfully")),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation      : 0,
        backgroundColor: AppColors.background,
        title: const Text(
          "Select Member",
          style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag        : "operations",
            backgroundColor: Colors.black87,
            onPressed      : _showOperationsBottomSheet,
            icon : const Icon(Icons.more_horiz_rounded, color: Colors.white),
            label: const Text("Operations", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag        : "add",
            backgroundColor: AppColors.primary,
            onPressed      : _showAddMemberDialog,
            icon : const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Member", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
          ? const Center(child: Text("No members found"))
          : ListView.builder(
        padding   : const EdgeInsets.all(20),
        itemCount : _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color       : AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border      : Border.all(color: AppColors.divider),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: CircleAvatar(
                radius         : 26,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  (member["full_name"] ?? "?")[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              title   : Text(member["full_name"] ?? "", style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member["relationship"] ?? ""),
                    const SizedBox(height: 4),
                    Text(member["pan_number"]   ?? ""),
                  ],
                ),
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StartFilingScreen(member: member)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}