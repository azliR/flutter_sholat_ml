// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ml_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MlModel _$MlModelFromJson(Map<String, dynamic> json) {
  return _MlModel.fromJson(json);
}

/// @nodoc
mixin _$MlModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  MlModelConfig get config => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_MlModel value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_MlModel value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_MlModel value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this MlModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MlModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MlModelCopyWith<MlModel> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MlModelCopyWith<$Res> {
  factory $MlModelCopyWith(MlModel value, $Res Function(MlModel) then) =
      _$MlModelCopyWithImpl<$Res, MlModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      String path,
      String? description,
      DateTime createdAt,
      DateTime updatedAt,
      MlModelConfig config});

  $MlModelConfigCopyWith<$Res> get config;
}

/// @nodoc
class _$MlModelCopyWithImpl<$Res, $Val extends MlModel>
    implements $MlModelCopyWith<$Res> {
  _$MlModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MlModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? path = null,
    Object? description = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? config = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      config: null == config
          ? _value.config
          : config // ignore: cast_nullable_to_non_nullable
              as MlModelConfig,
    ) as $Val);
  }

  /// Create a copy of MlModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MlModelConfigCopyWith<$Res> get config {
    return $MlModelConfigCopyWith<$Res>(_value.config, (value) {
      return _then(_value.copyWith(config: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MlModelImplCopyWith<$Res> implements $MlModelCopyWith<$Res> {
  factory _$$MlModelImplCopyWith(
          _$MlModelImpl value, $Res Function(_$MlModelImpl) then) =
      __$$MlModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String path,
      String? description,
      DateTime createdAt,
      DateTime updatedAt,
      MlModelConfig config});

  @override
  $MlModelConfigCopyWith<$Res> get config;
}

/// @nodoc
class __$$MlModelImplCopyWithImpl<$Res>
    extends _$MlModelCopyWithImpl<$Res, _$MlModelImpl>
    implements _$$MlModelImplCopyWith<$Res> {
  __$$MlModelImplCopyWithImpl(
      _$MlModelImpl _value, $Res Function(_$MlModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of MlModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? path = null,
    Object? description = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? config = null,
  }) {
    return _then(_$MlModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      config: null == config
          ? _value.config
          : config // ignore: cast_nullable_to_non_nullable
              as MlModelConfig,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MlModelImpl implements _MlModel {
  const _$MlModelImpl(
      {required this.id,
      required this.name,
      required this.path,
      required this.description,
      required this.createdAt,
      required this.updatedAt,
      this.config = const MlModelConfig(
          enableTeacherForcing: false,
          batchSize: 1,
          windowSize: 20,
          numberOfFeatures: 3,
          inputDataType: InputDataType.float32,
          temporalConsistencyEnforcements: {})});

  factory _$MlModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MlModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String path;
  @override
  final String? description;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final MlModelConfig config;

  @override
  String toString() {
    return 'MlModel(id: $id, name: $name, path: $path, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, config: $config)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MlModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.config, config) || other.config == config));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, path, description, createdAt, updatedAt, config);

  /// Create a copy of MlModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MlModelImplCopyWith<_$MlModelImpl> get copyWith =>
      __$$MlModelImplCopyWithImpl<_$MlModelImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_MlModel value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_MlModel value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_MlModel value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$MlModelImplToJson(
      this,
    );
  }
}

abstract class _MlModel implements MlModel {
  const factory _MlModel(
      {required final String id,
      required final String name,
      required final String path,
      required final String? description,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final MlModelConfig config}) = _$MlModelImpl;

  factory _MlModel.fromJson(Map<String, dynamic> json) = _$MlModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get path;
  @override
  String? get description;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  MlModelConfig get config;

  /// Create a copy of MlModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MlModelImplCopyWith<_$MlModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
