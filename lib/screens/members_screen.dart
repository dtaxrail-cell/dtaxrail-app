import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/member_service.dart';
import 'start_filing_screen.dart';

class MembersScreen extends StatefulWidget {

  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() =>
      _MembersScreenState();
}

class _MembersScreenState
    extends State<MembersScreen> {

  bool _isLoading = true;

  List<dynamic> _members = [];

  @override
  void initState() {

    super.initState();

    _loadMembers();
  }

  Future<void> _loadMembers() async {

    setState(() {
      _isLoading = true;
    });

    final members =
    await MemberService.getMembers();

    if (!mounted) return;

    setState(() {

      _members = members;

      _isLoading = false;
    });
  }

  Future<void> _showAddMemberDialog() async {

    final nameCtrl =
    TextEditingController();

    final panCtrl =
    TextEditingController();

    final phoneCtrl =
    TextEditingController();

    final emailCtrl =
    TextEditingController();

    final dobCtrl =
    TextEditingController();

    final relationCtrl =
    TextEditingController();

    bool isSaving = false;

    showDialog(

      context: context,

      builder: (_) {

        return StatefulBuilder(

          builder: (context, setDialogState) {

            return AlertDialog(

              shape: RoundedRectangleBorder(

                borderRadius:
                BorderRadius.circular(20),
              ),

              title: const Text(

                "Add Member",

                style: TextStyle(

                  fontFamily: 'Poppins',

                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              content: SingleChildScrollView(

                child: Column(

                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    _buildField(
                      controller: nameCtrl,
                      label: "Full Name",
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller: panCtrl,
                      label: "PAN Number",
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller: phoneCtrl,
                      label: "Phone Number",
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller: emailCtrl,
                      label: "Email Address",
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller: dobCtrl,
                      label: "Date of Birth",
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller: relationCtrl,
                      label: "Relationship",
                    ),
                  ],
                ),
              ),

              actions: [

                TextButton(

                  onPressed: () {

                    Navigator.pop(context);
                  },

                  child: const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(

                  onPressed: isSaving
                      ? null
                      : () async {

                    if (
                    nameCtrl.text
                        .trim()
                        .isEmpty
                    ) {
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    final response =
                    await MemberService
                        .createMember(

                      fullName:
                      nameCtrl.text.trim(),

                      panNumber:
                      panCtrl.text.trim(),

                      phone:
                      phoneCtrl.text.trim(),

                      email:
                      emailCtrl.text.trim(),

                      relationship:
                      relationCtrl.text.trim(),

                      dateOfBirth:
                      dobCtrl.text.trim(),
                    );

                    if (!mounted) return;

                    setDialogState(() {
                      isSaving = false;
                    });

                    if (response != null) {

                      Navigator.pop(context);

                      await _loadMembers();

                      if (!mounted) return;

                      ScaffoldMessenger.of(
                          context)
                          .showSnackBar(

                        const SnackBar(

                          content: Text(
                            "Member added successfully",
                          ),
                        ),
                      );
                    }
                  },

                  child: isSaving

                      ? const SizedBox(

                    width: 18,
                    height: 18,

                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )

                      : const Text(
                    "Save",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOperationsBottomSheet() {

    showModalBottomSheet(

      context: context,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),

      builder: (_) {

        return Padding(

          padding: const EdgeInsets.all(20),

          child: Column(

            mainAxisSize:
            MainAxisSize.min,

            children: [

              Container(

                width: 40,
                height: 5,

                decoration: BoxDecoration(

                  color: Colors.grey.shade300,

                  borderRadius:
                  BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 24),

              ListTile(

                leading: const Icon(
                  Icons.edit_rounded,
                ),

                title: const Text(
                  "Edit Member",
                ),

                onTap: () {

                  Navigator.pop(context);

                  _showMemberSelector(
                    isDelete: false,
                  );
                },
              ),

              ListTile(

                leading: const Icon(

                  Icons.delete_rounded,

                  color: Colors.red,
                ),

                title: const Text(

                  "Delete Member",

                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),

                onTap: () {

                  Navigator.pop(context);

                  _showMemberSelector(
                    isDelete: true,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMemberSelector({
    required bool isDelete,
  }) {

    showModalBottomSheet(

      context: context,

      builder: (_) {

        return ListView.builder(

          shrinkWrap: true,

          itemCount:
          _members.length,

          itemBuilder:
              (context, index) {

            final member =
            _members[index];

            return ListTile(

              leading: CircleAvatar(

                child: Text(

                  member["full_name"][0]
                      .toUpperCase(),
                ),
              ),

              title: Text(
                member["full_name"],
              ),

              subtitle: Text(
                member["relationship"] ?? "",
              ),

              onTap: () {

                Navigator.pop(context);

                if (isDelete) {

                  _deleteMember(member);

                } else {

                  _showEditMemberDialog(
                    member,
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showEditMemberDialog(
      dynamic member,
      ) async {

    final nameCtrl =
    TextEditingController(
      text: member["full_name"],
    );

    final panCtrl =
    TextEditingController(
      text: member["pan_number"],
    );

    final phoneCtrl =
    TextEditingController(
      text: member["phone"],
    );

    final emailCtrl =
    TextEditingController(
      text: member["email"],
    );

    final dobCtrl =
    TextEditingController(
      text: member["date_of_birth"],
    );

    final relationCtrl =
    TextEditingController(
      text: member["relationship"],
    );

    bool isSaving = false;

    showDialog(

      context: context,

      builder: (_) {

        return StatefulBuilder(

          builder: (context, setDialogState) {

            return AlertDialog(

              title: const Text(
                "Edit Member",
              ),

              content:
              SingleChildScrollView(

                child: Column(

                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    _buildField(
                      controller: nameCtrl,
                      label: "Full Name",
                    ),

                    const SizedBox(height: 12),

                    _buildField(
                      controller: panCtrl,
                      label: "PAN Number",
                    ),

                    const SizedBox(height: 12),

                    _buildField(
                      controller: phoneCtrl,
                      label: "Phone Number",
                    ),

                    const SizedBox(height: 12),

                    _buildField(
                      controller: emailCtrl,
                      label: "Email",
                    ),

                    const SizedBox(height: 12),

                    _buildField(
                      controller: dobCtrl,
                      label: "DOB",
                    ),

                    const SizedBox(height: 12),

                    _buildField(
                      controller: relationCtrl,
                      label: "Relationship",
                    ),
                  ],
                ),
              ),

              actions: [

                TextButton(

                  onPressed: () {

                    Navigator.pop(context);
                  },

                  child: const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(

                  onPressed: isSaving
                      ? null
                      : () async {

                    setDialogState(() {
                      isSaving = true;
                    });

                    final success =
                    await MemberService
                        .updateMember(

                      memberId:
                      member["id"]
                          .toString(),

                      fullName:
                      nameCtrl.text,

                      panNumber:
                      panCtrl.text,

                      phone:
                      phoneCtrl.text,

                      email:
                      emailCtrl.text,

                      relationship:
                      relationCtrl.text,

                      dateOfBirth:
                      dobCtrl.text,
                    );

                    if (!mounted) return;

                    setDialogState(() {
                      isSaving = false;
                    });

                    if (success) {

                      Navigator.pop(context);

                      await _loadMembers();

                      ScaffoldMessenger.of(
                          context)
                          .showSnackBar(

                        const SnackBar(

                          content: Text(
                            "Member updated successfully",
                          ),
                        ),
                      );
                    }
                  },

                  child: const Text(
                    "Update",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteMember(
      dynamic member,
      ) async {

    final confirm =
    await showDialog<bool>(

      context: context,

      builder: (_) {

        return AlertDialog(

          title: const Text(
            "Delete Member",
          ),

          content: Text(

            "Delete ${member["full_name"]} and all filings?",
          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(
                    context,
                    false);
              },

              child: const Text(
                "Cancel",
              ),
            ),

            ElevatedButton(

              style:
              ElevatedButton.styleFrom(

                backgroundColor:
                Colors.red,
              ),

              onPressed: () {

                Navigator.pop(
                    context,
                    true);
              },

              child: const Text(
                "Delete",
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    final success =
    await MemberService.deleteMember(
      member["id"].toString(),
    );

    if (success) {

      await _loadMembers();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Member deleted successfully",
          ),
        ),
      );
    }
  }

  Widget _buildField({

    required TextEditingController controller,

    required String label,

  }) {

    return TextField(

      controller: controller,

      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      AppColors.background,

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
        AppColors.background,

        title: const Text(

          "Select Member",

          style: TextStyle(

            fontWeight:
            FontWeight.w700,

            fontFamily:
            'Poppins',
          ),
        ),
      ),

      floatingActionButton: Row(

        mainAxisAlignment:
        MainAxisAlignment.end,

        children: [

          FloatingActionButton.extended(

            heroTag: "operations",

            backgroundColor:
            Colors.black87,

            onPressed:
            _showOperationsBottomSheet,

            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
            ),

            label: const Text(

              "Operations",

              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 12),

          FloatingActionButton.extended(

            heroTag: "add",

            backgroundColor:
            AppColors.primary,

            onPressed:
            _showAddMemberDialog,

            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),

            label: const Text(

              "Add Member",

              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      body: _isLoading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : _members.isEmpty

          ? const Center(

        child: Text(
          "No members found",
        ),
      )

          : ListView.builder(

        padding:
        const EdgeInsets.all(20),

        itemCount:
        _members.length,

        itemBuilder:
            (context, index) {

          final member =
          _members[index];

          return Container(

            margin:
            const EdgeInsets.only(
              bottom: 16,
            ),

            decoration: BoxDecoration(

              color:
              AppColors.cardBg,

              borderRadius:
              BorderRadius.circular(20),

              border: Border.all(
                color:
                AppColors.divider,
              ),
            ),

            child: ListTile(

              contentPadding:
              const EdgeInsets.all(18),

              leading: CircleAvatar(

                radius: 26,

                backgroundColor:
                AppColors.primaryLight,

                child: Text(

                  member["full_name"][0]
                      .toUpperCase(),

                  style: const TextStyle(

                    color:
                    AppColors.primary,

                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              title: Text(

                member["full_name"],

                style: const TextStyle(

                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              subtitle: Padding(

                padding:
                const EdgeInsets.only(
                  top: 6,
                ),

                child: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      member["relationship"] ?? "",
                    ),

                    const SizedBox(height: 4),

                    Text(
                      member["pan_number"] ?? "",
                    ),
                  ],
                ),
              ),

              onTap: () async {

                await Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) =>
                        StartFilingScreen(

                          member: member,
                        ),
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