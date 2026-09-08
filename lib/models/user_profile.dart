class UserProfile {
  String name;
  String occupation;
  String phone;
  String email;
  String address;
  String dob;
  String avatarPath;
  String primaryBank;
  String secondaryBank;
  String mfs;

  UserProfile({
    this.name = '',
    this.occupation = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.dob = '',
    this.avatarPath = '',
    this.primaryBank = '',
    this.secondaryBank = '',
    this.mfs = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'occupation': occupation,
        'phone': phone,
        'email': email,
        'address': address,
        'dob': dob,
        'avatarPath': avatarPath,
        'primaryBank': primaryBank,
        'secondaryBank': secondaryBank,
        'mfs': mfs,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? '',
        occupation: json['occupation'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        address: json['address'] ?? '',
        dob: json['dob'] ?? '',
        avatarPath: json['avatarPath'] ?? '',
        primaryBank: json['primaryBank'] ?? '',
        secondaryBank: json['secondaryBank'] ?? '',
        mfs: json['mfs'] ?? '',
      );
}
