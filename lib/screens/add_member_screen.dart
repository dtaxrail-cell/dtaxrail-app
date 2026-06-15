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

  // CHANGE 5: Full relationship list with Friend & Others added
  static const List<String> _relationships = [
    "Self", "Mother", "Father", "Sister", "Brother", "Friend", "Others",
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
      _members  = members;
      _isLoading = false;
    });
  }

  // ─── Validators ──────────────────────────────────────────────────────────────

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);

  bool _isValidPan(String pan) =>
      RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan);

  // ─── DOB helper: always sends DD-MM-YYYY to backend ──────────────────────────
  // Flutter's DateTime gives us year/month/day clearly — no ambiguity
  String _formatDob(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";

  // ─── Shared date picker ───────────────────────────────────────────────────────

  Future<DateTime?> _pickDate(BuildContext ctx, {DateTime? initial}) {
    return showDatePicker(
      context    : ctx,
      initialDate: initial ?? DateTime(2000),
      firstDate  : DateTime(1940),
      lastDate   : DateTime.now(),
    );
  }

  // ─── Add Member Dialog ────────────────────────────────────────────────────────

  Future<void> _showAddMemberDialog() async {
    final nameCtrl   = TextEditingController();
    final panCtrl    = TextEditingController();
    final phoneCtrl  = TextEditingController();
    final emailCtrl  = TextEditingController();
    final dobCtrl    = TextEditingController();
    final scrollCtrl = ScrollController();

    String relationship = "Self";
    bool isSaving       = false;
    bool panTouched     = false;
    bool emailTouched   = false;
    bool phoneTouched   = false;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {

          String? panError() {
            if (!panTouched || panCtrl.text.isEmpty) return null;
            return _isValidPan(panCtrl.text) ? null : "Format: ABCDE1234F";
          }
          String? emailError() {
            if (!emailTouched || emailCtrl.text.isEmpty) return null;
            return _isValidEmail(emailCtrl.text) ? null : "Enter valid email";
          }
          String? phoneError() {
            if (!phoneTouched || phoneCtrl.text.isEmpty) return null;
            return phoneCtrl.text.length == 10 ? null : "Must be 10 digits";
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              "Add Member",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
            ),
            insetPadding: EdgeInsets.only(
              left  : 20, right: 20, top: 40,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Scrollbar(
                controller    : scrollCtrl,
                thumbVisibility: true,
                thickness     : 5,
                radius        : const Radius.circular(4),
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // Full Name
                      TextField(
                        controller           : nameCtrl,
                        textCapitalization   : TextCapitalization.characters,
                        inputFormatters      : [UpperCaseTextFormatter()],
                        decoration           : const InputDecoration(
                          labelText : "Full Name",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // PAN
                      TextField(
                        controller        : panCtrl,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters   : [
                          UpperCaseTextFormatter(),
                          LengthLimitingTextInputFormatter(10),
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                        ],
                        onChanged: (_) => setDialogState(() => panTouched = true),
                        decoration: InputDecoration(
                          labelText : "PAN Number",
                          hintText  : "ABCDE1234F",
                          prefixIcon: const Icon(Icons.credit_card_outlined),
                          errorText : panError(),
                          suffixIcon: panTouched && panError() == null && panCtrl.text.isNotEmpty
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Phone
                      TextField(
                        controller     : phoneCtrl,
                        keyboardType   : TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (_) => setDialogState(() => phoneTouched = true),
                        decoration: InputDecoration(
                          labelText : "Phone Number",
                          prefixIcon: const Icon(Icons.phone_outlined),
                          errorText : phoneError(),
                          suffixIcon: phoneTouched && phoneError() == null && phoneCtrl.text.isNotEmpty
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextField(
                        controller     : emailCtrl,
                        keyboardType   : TextInputType.emailAddress,
                        inputFormatters: [LowerCaseTextFormatter()],
                        onChanged: (_) => setDialogState(() => emailTouched = true),
                        decoration: InputDecoration(
                          labelText : "Email Address",
                          prefixIcon: const Icon(Icons.email_outlined),
                          errorText : emailError(),
                          suffixIcon: emailTouched && emailError() == null && emailCtrl.text.isNotEmpty
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // DOB — calendar picker, bug-fixed format
                      TextField(
                        controller: dobCtrl,
                        readOnly  : true,
                        onTap     : () async {
                          final picked = await _pickDate(ctx);
                          if (picked != null) {
                            setDialogState(() => dobCtrl.text = _formatDob(picked));
                          }
                        },
                        decoration: const InputDecoration(
                          labelText : "Date of Birth",
                          prefixIcon: Icon(Icons.cake_outlined),
                          suffixIcon: Icon(Icons.calendar_month),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // CHANGE 5: Relationship dropdown with Friend & Others
                      DropdownButtonFormField<String>(
                        value     : relationship,
                        decoration: const InputDecoration(
                          labelText : "Relationship",
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        items: _relationships
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setDialogState(() => relationship = v ?? "Self"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child    : const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                  setDialogState(() {
                    panTouched   = true;
                    emailTouched = true;
                    phoneTouched = true;
                  });

                  if (nameCtrl.text.trim().isEmpty  ||
                      panCtrl.text.trim().isEmpty   ||
                      phoneCtrl.text.trim().isEmpty ||
                      emailCtrl.text.trim().isEmpty ||
                      dobCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }
                  if (panError() != null || emailError() != null || phoneError() != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fix the errors before saving")),
                    );
                    return;
                  }

                  setDialogState(() => isSaving = true);

                  final response = await MemberService.createMember(
                    fullName    : nameCtrl.text.trim(),
                    panNumber   : panCtrl.text.trim(),
                    phone       : phoneCtrl.text.trim(),
                    email       : emailCtrl.text.trim(),
                    relationship: relationship,
                    dateOfBirth : dobCtrl.text.trim(),
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
          );
        },
      ),
    );
  }

  // ─── Edit Member Dialog ───────────────────────────────────────────────────────

  Future<void> _showEditMemberDialog(dynamic member) async {
    final nameCtrl   = TextEditingController(text: member["full_name"]);
    final panCtrl    = TextEditingController(text: member["pan_number"]);
    final phoneCtrl  = TextEditingController(text: member["phone"]);
    final emailCtrl  = TextEditingController(text: member["email"]);
    final dobCtrl    = TextEditingController(text: member["date_of_birth"] ?? "");
    final scrollCtrl = ScrollController();

    // Guard: if saved relationship isn't in list, fall back to "Others"
    final savedRel   = member["relationship"] ?? "Self";
    String relationship = _relationships.contains(savedRel) ? savedRel : "Others";

    bool isSaving    = false;
    bool panTouched  = true;
    bool emailTouched= true;
    bool phoneTouched= true;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {

          String? panError() {
            if (!panTouched || panCtrl.text.isEmpty) return null;
            return _isValidPan(panCtrl.text) ? null : "Format: ABCDE1234F";
          }
          String? emailError() {
            if (!emailTouched || emailCtrl.text.isEmpty) return null;
            return _isValidEmail(emailCtrl.text) ? null : "Enter valid email";
          }
          String? phoneError() {
            if (!phoneTouched || phoneCtrl.text.isEmpty) return null;
            return phoneCtrl.text.length == 10 ? null : "Must be 10 digits";
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              "Edit Member",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
            ),
            insetPadding: EdgeInsets.only(
              left  : 20, right: 20, top: 40,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Scrollbar(
                controller    : scrollCtrl,
                thumbVisibility: true,
                thickness     : 5,
                radius        : const Radius.circular(4),
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller        : nameCtrl,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters   : [UpperCaseTextFormatter()],
                        decoration        : const InputDecoration(
                          labelText: "Full Name", prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller        : panCtrl,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters   : [
                          UpperCaseTextFormatter(),
                          LengthLimitingTextInputFormatter(10),
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                        ],
                        onChanged: (_) => setDialogState(() => panTouched = true),
                        decoration: InputDecoration(
                          labelText : "PAN Number",
                          hintText  : "ABCDE1234F",
                          prefixIcon: const Icon(Icons.credit_card_outlined),
                          errorText : panError(),
                          suffixIcon: panTouched && panError() == null && panCtrl.text.isNotEmpty
                              ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller     : phoneCtrl,
                        keyboardType   : TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (_) => setDialogState(() => phoneTouched = true),
                        decoration: InputDecoration(
                          labelText : "Phone Number",
                          prefixIcon: const Icon(Icons.phone_outlined),
                          errorText : phoneError(),
                          suffixIcon: phoneTouched && phoneError() == null && phoneCtrl.text.isNotEmpty
                              ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller     : emailCtrl,
                        keyboardType   : TextInputType.emailAddress,
                        inputFormatters: [LowerCaseTextFormatter()],
                        onChanged: (_) => setDialogState(() => emailTouched = true),
                        decoration: InputDecoration(
                          labelText : "Email Address",
                          prefixIcon: const Icon(Icons.email_outlined),
                          errorText : emailError(),
                          suffixIcon: emailTouched && emailError() == null && emailCtrl.text.isNotEmpty
                              ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // DOB bug-fixed
                      TextField(
                        controller: dobCtrl,
                        readOnly  : true,
                        onTap     : () async {
                          DateTime? initial;
                          try {
                            // Try parsing existing value (DD-MM-YYYY)
                            final parts = dobCtrl.text.split('-');
                            if (parts.length == 3) {
                              initial = DateTime(
                                int.parse(parts[2]),
                                int.parse(parts[1]),
                                int.parse(parts[0]),
                              );
                            }
                          } catch (_) {}
                          final picked = await _pickDate(ctx, initial: initial);
                          if (picked != null) {
                            setDialogState(() => dobCtrl.text = _formatDob(picked));
                          }
                        },
                        decoration: const InputDecoration(
                          labelText : "Date of Birth",
                          prefixIcon: Icon(Icons.cake_outlined),
                          suffixIcon: Icon(Icons.calendar_month),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // CHANGE 5: Relationship with Friend & Others
                      DropdownButtonFormField<String>(
                        value     : relationship,
                        decoration: const InputDecoration(
                          labelText : "Relationship",
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        items: _relationships
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setDialogState(() => relationship = v ?? "Self"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child    : const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                  setDialogState(() {
                    panTouched   = true;
                    emailTouched = true;
                    phoneTouched = true;
                  });
                  if (panError() != null || emailError() != null || phoneError() != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fix errors before updating")),
                    );
                    return;
                  }
                  setDialogState(() => isSaving = true);

                  final success = await MemberService.updateMember(
                    memberId    : member["id"].toString(),
                    fullName    : nameCtrl.text.trim(),
                    panNumber   : panCtrl.text.trim(),
                    phone       : phoneCtrl.text.trim(),
                    email       : emailCtrl.text.trim(),
                    relationship: relationship,
                    dateOfBirth : dobCtrl.text.trim(),
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
          );
        },
      ),
    );
  }

  // ─── Operations / Delete (unchanged) ─────────────────────────────────────────

  void _showOperationsBottomSheet() {
    showModalBottomSheet(
      context         : context,
      backgroundColor : Colors.white,
      shape           : const RoundedRectangleBorder(
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title  : const Text("Edit Member"),
              onTap  : () {
                Navigator.pop(context);
                _showMemberSelector(isDelete: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title  : const Text("Delete Member", style: TextStyle(color: Colors.red)),
              onTap  : () {
                Navigator.pop(context);
                _showMemberSelector(isDelete: true);
              },
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
            leading : CircleAvatar(child: Text(member["full_name"][0].toUpperCase())),
            title   : Text(member["full_name"]),
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

  Future<void> _deleteMember(dynamic member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text("Delete Member"),
        content: Text("Delete ${member["full_name"]} and all filings?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text("Cancel"),
          ),
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
        padding    : const EdgeInsets.all(20),
        itemCount  : _members.length,
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
                  member["full_name"][0].toUpperCase(),
                  style: const TextStyle(
                    color     : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                member["full_name"],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member["relationship"] ?? ""),
                    const SizedBox(height: 4),
                    Text(member["pan_number"] ?? ""),
                  ],
                ),
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StartFilingScreen(member: member),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Formatters ───────────────────────────────────────────────────────────────

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      TextEditingValue(text: n.text.toUpperCase(), selection: n.selection);
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      TextEditingValue(text: n.text.toLowerCase(), selection: n.selection);
}