class UserModel {
  final String  id;
  final String  username;
  final String  fullName;
  final String? bio;
  final String? avatarUrl;
  final String  createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:        json['id']         as String,
        username:  json['username']   as String? ?? '',
        fullName:  json['full_name']  as String? ?? '',
        bio:       json['bio']        as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id':         id,
        'username':   username,
        'full_name':  fullName,
        'bio':        bio,
        'avatar_url': avatarUrl,
        'created_at': createdAt,
      };

  UserModel copyWith({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) =>
      UserModel(
        id:        id,
        username:  username  ?? this.username,
        fullName:  fullName  ?? this.fullName,
        bio:       bio       ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );
}
