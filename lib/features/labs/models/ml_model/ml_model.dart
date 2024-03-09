import 'package:equatable/equatable.dart';

class MlModel extends Equatable {
  const MlModel({
    required this.id,
    required this.name,
    required this.path,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? name;
  final String path;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MlModel.fromJson(Map<String, dynamic> map) {
    return MlModel(
      id: (map['id'] ?? '') as String,
      name: map['name'] != null ? map['name'] as String : null,
      path: (map['path'] ?? '') as String,
      description:
          map['description'] != null ? map['description'] as String : null,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch((map['createdAt'] ?? 0) as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch((map['updatedAt'] ?? 0) as int),
    );
  }

  MlModel copyWith({
    String? id,
    String? name,
    String? path,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MlModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'path': path,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        description,
        createdAt,
        updatedAt,
      ];
}
