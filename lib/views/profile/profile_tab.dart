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
  State<ProfileTab> createState() => ProfileTabState();
}

class ProfileTabState extends State<ProfileTab> {
  bool _isEditing = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _occCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _pBankCtrl;
  late TextEditingController _sBankCtrl;
  late TextEditingController _mfsCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addrCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final user = widget.dataController.userProfile;
    _nameCtrl = TextEditingController(text: user.name);
    _occCtrl = TextEditingController(text: user.occupation);
    _dobCtrl = TextEditingController(text: user.dob);
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
    _dobCtrl.dispose();
    _pBankCtrl.dispose();
    _sBankCtrl.dispose();
    _mfsCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  bool get _isProfileCreated =>
      widget.dataController.userProfile.name.trim().isNotEmpty;

  void showEditMode() {
    setState(() {
      _initControllers();
      _isEditing = true;
    });
  }

  void showViewMode() {
    setState(() {
      _isEditing = false;
    });
  }

  void _saveProfile() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your full name')));
      return;
    }

    final user = widget.dataController.userProfile;
    user.name = _nameCtrl.text.trim();
    user.occupation = _occCtrl.text.trim();
    user.dob = _dobCtrl.text.trim();
    user.primaryBank = _pBankCtrl.text.trim();
    user.secondaryBank = _sBankCtrl.text.trim();
    user.mfs = _mfsCtrl.text.trim();
    user.phone = _phoneCtrl.text.trim();
    user.email = _emailCtrl.text.trim();
    user.address = _addrCtrl.text.trim();

    widget.dataController.saveUserProfile();
    widget.onDataChanged();

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile saved successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isProfileCreated) {
      return _buildCreateProfileView();
    }

    if (_isEditing) {
      return _buildEditProfileView();
    }

    return _buildProfileDetailView();
  }

  // ---------------------------------------------------------------------------
  // 1. CREATE PROFILE VIEW (First Time User Flow)
  // ---------------------------------------------------------------------------
  Widget _buildCreateProfileView() {
    final user = widget.dataController.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Welcome
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome to PERFINAX!',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      const Text(
                          'Create your profile to unlock customized tax planning & financial statements.',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.slate300)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Form Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CREATE YOUR PROFILE',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                        letterSpacing: 0.5)),
                const SizedBox(height: 16),

                // Avatar Selector
                Center(
                  child: Column(
                    children: [
                      user.avatarPath.isNotEmpty &&
                              File(user.avatarPath).existsSync()
                          ? CircleAvatar(
                              radius: 36,
                              backgroundImage: FileImage(File(user.avatarPath)))
                          : CircleAvatar(
                              radius: 36,
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              child: const Icon(Icons.person,
                                  size: 40, color: Color(0xFF10B981))),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final XFile? img = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (img != null) {
                            user.avatarPath = img.path;
                            widget.dataController.saveUserProfile();
                            widget.onDataChanged();
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.camera_alt_rounded,
                            size: 16, color: Color(0xFF10B981)),
                        label: const Text('Add Profile Photo',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildInputField(_nameCtrl, 'Full Name *', 'e.g. Ahsun Habib',
                    Icons.person_outline),
                _buildInputField(_occCtrl, 'Occupation',
                    'e.g. Software Engineer', Icons.work_outline),
                _buildInputField(_phoneCtrl, 'Phone Number',
                    'e.g. +8801700000000', Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                _buildInputField(_emailCtrl, 'Email Address',
                    'e.g. user@example.com', Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                _buildInputField(_pBankCtrl, 'Primary Bank Name',
                    'e.g. City Bank', Icons.account_balance_outlined),
                _buildInputField(_sBankCtrl, 'Secondary Bank Name',
                    'e.g. BRAC Bank', Icons.account_balance_wallet_outlined),
                _buildInputField(_mfsCtrl, 'Mobile Banking (MFS)',
                    'e.g. bKash / Nagad', Icons.phone_android_outlined),
                _buildInputField(_addrCtrl, 'Address',
                    'e.g. Dhaka, Bangladesh', Icons.location_on_outlined),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('CREATE PROFILE',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. PROFILE VIEW SCREEN (Show details when profile exists)
  // ---------------------------------------------------------------------------
  Widget _buildProfileDetailView() {
    final user = widget.dataController.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    user.avatarPath.isNotEmpty &&
                            File(user.avatarPath).existsSync()
                        ? CircleAvatar(
                            radius: 32,
                            backgroundImage: FileImage(File(user.avatarPath)))
                        : Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.emerald
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.person,
                                size: 36, color: Color(0xFF10B981)),
                          ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 2),
                          Text(
                              user.occupation.isNotEmpty
                                  ? user.occupation
                                  : 'Financial Member',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF34D399),
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF064E3B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Verified Profile',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFFA7F3D0),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _initControllers();
                        _isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('EDIT PROFILE',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contact & Personal Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PERSONAL & CONTACT INFORMATION',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34D399),
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                _buildDetailRow(
                    Icons.phone, 'Phone', user.phone, 'Not specified'),
                _buildDetailRow(
                    Icons.email, 'Email', user.email, 'Not specified'),
                _buildDetailRow(Icons.location_on, 'Address', user.address,
                    'Not specified'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Banking Accounts Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BANKING & ACCOUNTS',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34D399),
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.account_balance, 'Primary Bank',
                    user.primaryBank, 'Not configured'),
                _buildDetailRow(Icons.account_balance_wallet,
                    'Secondary Bank', user.secondaryBank, 'Not configured'),
                _buildDetailRow(Icons.phone_android, 'Mobile Banking (MFS)',
                    user.mfs, 'Not configured'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. EDIT PROFILE VIEW (Update Existing Profile Flow)
  // ---------------------------------------------------------------------------
  Widget _buildEditProfileView() {
    final user = widget.dataController.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('UPDATE YOUR PROFILE',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981))),
                IconButton(
                  onPressed: () => setState(() => _isEditing = false),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.slate400),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Avatar Photo Change
            Row(
              children: [
                user.avatarPath.isNotEmpty &&
                        File(user.avatarPath).existsSync()
                    ? CircleAvatar(
                        radius: 28,
                        backgroundImage: FileImage(File(user.avatarPath)))
                    : CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        child: const Icon(Icons.person,
                            size: 32, color: Color(0xFF10B981))),
                const SizedBox(width: 14),
                ElevatedButton.icon(
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
                  icon: const Icon(Icons.photo_camera_rounded, size: 14),
                  label: const Text('Change Photo',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      foregroundColor: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInputField(
                _nameCtrl, 'Full Name *', 'Full Name', Icons.person_outline),
            _buildInputField(_occCtrl, 'Occupation', 'Occupation',
                Icons.work_outline),
            _buildInputField(_phoneCtrl, 'Phone Number', 'Phone Number',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            _buildInputField(_emailCtrl, 'Email Address', 'Email Address',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            _buildInputField(_pBankCtrl, 'Primary Bank Name',
                'Primary Bank Name', Icons.account_balance_outlined),
            _buildInputField(_sBankCtrl, 'Secondary Bank Name',
                'Secondary Bank Name', Icons.account_balance_wallet_outlined),
            _buildInputField(_mfsCtrl, 'Mobile Banking Name',
                'Mobile Banking Name', Icons.phone_android_outlined),
            _buildInputField(_addrCtrl, 'Address', 'Address',
                Icons.location_on_outlined),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.slate500
                              : const Color(0xFF94A3B8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CANCEL',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SAVE CHANGES',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildInputField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF34D399))),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.slate500
                      : const Color(0xFF64748B),
                  fontSize: 11),
              prefixIcon: Icon(icon, size: 16, color: AppColors.slate400),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, String fallback) {
    final hasVal = value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.slate400,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  hasVal ? value : fallback,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasVal
                          ? Theme.of(context).colorScheme.onSurface
                          : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.slate500
                              : const Color(0xFF64748B))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
