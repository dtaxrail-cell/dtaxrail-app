import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

import '../services/member_service.dart';

class AddMemberScreen extends StatefulWidget {

  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() =>
      _AddMemberScreenState();
}

class _AddMemberScreenState
    extends State<AddMemberScreen> {

  final _nameCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _relationshipCtrl =
  TextEditingController(text: "Self");

  final _dobCtrl = TextEditingController();

  bool _isLoading = false;

  Future<void> _pickDate() async {

    final picked =
    await showDatePicker(

      context: context,

      initialDate: DateTime(2000),

      firstDate: DateTime(1940),

      lastDate: DateTime.now(),
    );

    if (picked != null) {

      _dobCtrl.text =
      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _saveMember() async {

    if (_nameCtrl.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result =
    await MemberService.createMember(

      fullName: _nameCtrl.text,
      panNumber: _panCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      relationship: _relationshipCtrl.text,
      dateOfBirth: _dobCtrl.text,

    );

    setState(() {
      _isLoading = false;
    });

    if (result != null) {

      Navigator.pop(context, true);

    } else {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text("Failed to add member"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(

        backgroundColor: AppColors.background,
        elevation: 0,

        title: const Text(
          "Add Member",
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Full Name",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _panCtrl,
              decoration: const InputDecoration(
                labelText: "PAN Number",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: "Phone",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _relationshipCtrl,
              decoration: const InputDecoration(
                labelText: "Relationship",
              ),
            ),

            const SizedBox(height: 16),

            TextField(

              controller: _dobCtrl,

              readOnly: true,

              onTap: _pickDate,

              decoration: const InputDecoration(
                labelText: "Date of Birth",
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(

              width: double.infinity,

              child: PrimaryButton(

                label: "Save Member",

                onTap: _saveMember,

                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}