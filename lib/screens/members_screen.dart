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

      barrierDismissible: !isSaving,

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
                  fontWeight: FontWeight.w700,
                ),
              ),

              content: SingleChildScrollView(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    TextField(

                      controller: nameCtrl,

                      enabled: !isSaving,

                      decoration:
                      const InputDecoration(
                        labelText: "Full Name",
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(

                      controller: panCtrl,

                      enabled: !isSaving,

                      decoration:
                      const InputDecoration(
                        labelText: "PAN Number",
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(

                      controller: phoneCtrl,

                      enabled: !isSaving,

                      decoration:
                      const InputDecoration(
                        labelText: "Phone Number",
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(

                      controller: emailCtrl,

                      enabled: !isSaving,

                      decoration:
                      const InputDecoration(
                        labelText: "Email Address",
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(

                      controller: dobCtrl,

                      enabled: !isSaving,

                      decoration:
                      const InputDecoration(
                        labelText: "Date of Birth",
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(

                      controller: relationCtrl,

                      enabled: !isSaving,

                      decoration:
                      const InputDecoration(
                        labelText: "Relationship",
                      ),
                    ),
                  ],
                ),
              ),

              actions: [

                TextButton(

                  onPressed: isSaving
                      ? null
                      : () {

                    Navigator.pop(context);
                  },

                  child: const Text("Cancel"),
                ),

                ElevatedButton(

                  onPressed: isSaving
                      ? null
                      : () async {

                    if (nameCtrl.text.trim().isEmpty) {
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    final response =
                    await MemberService.createMember(

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

                      ScaffoldMessenger.of(context)
                          .showSnackBar(

                        const SnackBar(

                          content: Text(
                            "Member added successfully",
                          ),
                        ),
                      );

                    } else {

                      ScaffoldMessenger.of(context)
                          .showSnackBar(

                        const SnackBar(

                          content: Text(
                            "Failed to add member",
                          ),
                        ),
                      );
                    }
                  },

                  child: isSaving

                      ? const SizedBox(

                    height: 18,
                    width: 18,

                    child: CircularProgressIndicator(
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

      floatingActionButton:
      FloatingActionButton.extended(

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
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
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

          style: TextStyle(
            fontFamily: 'Poppins',
          ),
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

                    fontFamily:
                    'Poppins',
                  ),
                ),
              ),

              title: Text(

                member["full_name"],

                style: const TextStyle(

                  fontWeight:
                  FontWeight.w700,

                  fontFamily:
                  'Poppins',
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