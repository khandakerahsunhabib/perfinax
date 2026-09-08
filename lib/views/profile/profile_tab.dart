import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/data_controller.dart';

class ProfileTab extends StatefulWidget {
  final DataController dataController;
  final VoidCallback onDataChanged;

  const ProfileTab({
    super.key,
    required this.dataController,
    required this.onDataChanged,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _occCtrl;
  late TextEditingController _pBankCtrl;
  late TextEditingController _sBankCtrl;
  late TextEditingController _mfsCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addrCtrl;

  @override
  void initState() {
    super.initState();
    final user = widget.dataController.userProfile;
    _nameCtrl = TextEditingController(text: user.name);
    _occCtrl = TextEditingController(text: user.occupation);
    _pBankCtrl = TextEditingController(text: user.primaryBank);
    _sBankCtrl = TextEditingController(text: user.secondaryBank);
    _mfsCtrl = TextEditingController(text: user.mfs);
    _phoneCtrl = TextEditingController(text: user.phone);
    _emailCtrl = TextEditingController(text: user.email);
    _addrCtrl = TextEditingController(text: user.address);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _occCtrl.dispose();
    _pBankCtrl.dispose();
    _sBankCtrl.dispose();
    _mfsCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final user = widget.dataController.userProfile;
    user.name = _nameCtrl.text;
    user.occupation = _occCtrl.text;
    user.primaryBank = _pBankCtrl.text;
    user.secondaryBank = _sBankCtrl.text;
    user.mfs = _mfsCtrl.text;
    user.phone = _phoneCtrl.text;
    user.email = _emailCtrl.text;
    user.address = _addrCtrl.text;

    widget.dataController.saveUserProfile();
    widget.onDataChanged();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile information saved successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.dataController.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF0A221C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PROFILE SETTINGS',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 12),

            Row(
              children: [
                user.avatarPath.isNotEmpty && File(user.avatarPath).existsSync()
                    ? CircleAvatar(
                        radius: 24,
                        backgroundImage: FileImage(File(user.avatarPath)))
                    : const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF030A08),
                        child: Icon(Icons.person, color: Color(0xFF10B981))),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final XFile? img =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) {
                      user.avatarPath = img.path;
                      widget.dataController.saveUserProfile();
                      widget.onDataChanged();
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF030A08),
                      foregroundColor: Colors.white),
                  child: const Text('Change Photo',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(
                controller: _occCtrl,
                decoration: const InputDecoration(labelText: 'Occupation')),
            TextField(
                controller: _pBankCtrl,
                decoration:
                    const InputDecoration(labelText: 'Primary Bank Name')),
            TextField(
                controller: _sBankCtrl,
                decoration:
                    const InputDecoration(labelText: 'Secondary Bank Name')),
            TextField(
                controller: _mfsCtrl,
                decoration:
                    const InputDecoration(labelText: 'Mobile Banking Name')),
            TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number')),
            TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address')),
            TextField(
                controller: _addrCtrl,
                decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.black),
                child: const Text('SAVE PROFILE INFORMATION',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
