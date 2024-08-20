// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ml_model_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MlModelConfig _$MlModelConfigFromJson(Map<String, dynamic> json) {
  return _MlModelConfig.fromJson(json);
}

/// @nodoc
mixin _$MlModelConfig {
  bool get enableTeacherForcing => throw _privateConstructorUsedError;
  int get batchSize => throw _privateConstructorUsedError;
  int get windowSize => throw _privateConstructorUsedError;
  int get numberOfFeatures => throw _privateConstructorUsedError;
  InputDataType get inputDataType =>
      throw _privateConstructorUsedError; // required Set<Smoothing> smoothings,
// required Set<Filtering> filterings,
  Set<TemporalConsistencyEnforcement> get temporalConsistencyEnforcements =>
      throw _privateConstructorUsedError; // @Default({}) Set<Weighting> weightings,
  int get stepSize => throw _privateConstructorUsedError;

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_MlModelConfig value) $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_MlModelConfig value)? $default,
  ) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_MlModelConfig value)? $default, {
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this MlModelConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MlModelConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MlModelConfigCopyWith<MlModelConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MlModelConfigCopyWith<$Res> {
  factory $MlModelConfigCopyWith(
          MlModelConfig value, $Res Function(MlModelConfig) then) =
      _$MlModelConfigCopyWithImpl<$Res, MlModelConfig>;
  @useResult
  $Res call(
      {bool enableTeacherForcing,
      int batchSize,
      int windowSize,
      int numberOfFeatures,
      InputDataType inputDataType,
      Set<TemporalConsistencyEnforcement> temporalConsistencyEnforcements,
      int stepSize});
}

/// @nodoc
class _$MlModelConfigCopyWithImpl<$Res, $Val extends MlModelConfig>
    implements $MlModelConfigCopyWith<$Res> {
  _$MlModelConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MlModelConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enableTeacherForcing = null,
    Object? batchSize = null,
    Object? windowSize = null,
    Object? numberOfFeatures = null,
    Object? inputDataType = null,
    Object? temporalConsistencyEnforcements = null,
    Object? stepSize = null,
  }) {
    return _then(_value.copyWith(
      enableTeacherForcing: null == enableTeacherForcing
          ? _value.enableTeacherForcing
          : enableTeacherForcing // ignore: cast_nullable_to_non_nullable
              as bool,
      batchSize: null == batchSize
          ? _value.batchSize
          : batchSize // ignore: cast_nullable_to_non_nullable
              as int,
      windowSize: null == windowSize
          ? _value.windowSize
          : windowSize // ignore: cast_nullable_to_non_nullable
              as int,
      numberOfFeatures: null == numberOfFeatures
          ? _value.numberOfFeatures
          : numberOfFeatures // ignore: cast_nullable_to_non_nullable
              as int,
      inputDataType: null == inputDataType
          ? _value.inputDataType
          : inputDataType // ignore: cast_nullable_to_non_nullable
              as InputDataType,
      temporalConsistencyEnforcements: null == temporalConsistencyEnforcements
          ? _value.temporalConsistencyEnforcements
          : temporalConsistencyEnforcements // ignore: cast_nullable_to_non_nullable
              as Set<TemporalConsistencyEnforcement>,
      stepSize: null == stepSize
          ? _value.stepSize
          : stepSize // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MlModelConfigImplCopyWith<$Res>
    implements $MlModelConfigCopyWith<$Res> {
  factory _$$MlModelConfigImplCopyWith(
          _$MlModelConfigImpl value, $Res Function(_$MlModelConfigImpl) then) =
      __$$MlModelConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool enableTeacherForcing,
      int batchSize,
      int windowSize,
      int numberOfFeatures,
      InputDataType inputDataType,
      Set<TemporalConsistencyEnforcement> temporalConsistencyEnforcements,
      int stepSize});
}

/// @nodoc
class __$$MlModelConfigImplCopyWithImpl<$Res>
    extends _$MlModelConfigCopyWithImpl<$Res, _$MlModelConfigImpl>
    implements _$$MlModelConfigImplCopyWith<$Res> {
  __$$MlModelConfigImplCopyWithImpl(
      _$MlModelConfigImpl _value, $Res Function(_$MlModelConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of MlModelConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enableTeacherForcing = null,
    Object? batchSize = null,
    Object? windowSize = null,
    Object? numberOfFeatures = null,
    Object? inputDataType = null,
    Object? temporalConsistencyEnforcements = null,
    Object? stepSize = null,
  }) {
    return _then(_$MlModelConfigImpl(
      enableTeacherForcing: null == enableTeacherForcing
          ? _value.enableTeacherForcing
          : enableTeacherForcing // ignore: cast_nullable_to_non_nullable
              as bool,
      batchSize: null == batchSize
          ? _value.batchSize
          : batchSize // ignore: cast_nullable_to_non_nullable
              as int,
      windowSize: null == windowSize
          ? _value.windowSize
          : windowSize // ignore: cast_nullable_to_non_nullable
              as int,
      numberOfFeatures: null == numberOfFeatures
          ? _value.numberOfFeatures
          : numberOfFeatures // ignore: cast_nullable_to_non_nullable
              as int,
      inputDataType: null == inputDataType
          ? _value.inputDataType
          : inputDataType // ignore: cast_nullable_to_non_nullable
              as InputDataType,
      temporalConsistencyEnforcements: null == temporalConsistencyEnforcements
          ? _value._temporalConsistencyEnforcements
          : temporalConsistencyEnforcements // ignore: cast_nullable_to_non_nullable
              as Set<TemporalConsistencyEnforcement>,
      stepSize: null == stepSize
          ? _value.stepSize
          : stepSize // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MlModelConfigImpl implements _MlModelConfig {
  const _$MlModelConfigImpl(
      {required this.enableTeacherForcing,
      required this.batchSize,
      required this.windowSize,
      required this.numberOfFeatures,
      required this.inputDataType,
      required final Set<TemporalConsistencyEnforcement>
          temporalConsistencyEnforcements,
      this.stepSize = 10})
      : _temporalConsistencyEnforcements = temporalConsistencyEnforcements;

  factory _$MlModelConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$MlModelConfigImplFromJson(json);

  @override
  final bool enableTeacherForcing;
  @override
  final int batchSize;
  @override
  final int windowSize;
  @override
  final int numberOfFeatures;
  @override
  final InputDataType inputDataType;
// required Set<Smoothing> smoothings,
// required Set<Filtering> filterings,
  final Set<TemporalConsistencyEnforcement> _temporalConsistencyEnforcements;
// required Set<Smoothing> smoothings,
// required Set<Filtering> filterings,
  @override
  Set<TemporalConsistencyEnforcement> get temporalConsistencyEnforcements {
    if (_temporalConsistencyEnforcements is EqualUnmodifiableSetView)
      return _temporalConsistencyEnforcements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_temporalConsistencyEnforcements);
  }

// @Default({}) Set<Weighting> weightings,
  @override
  @JsonKey()
  final int stepSize;

  @override
  String toString() {
    return 'MlModelConfig(enableTeacherForcing: $enableTeacherForcing, batchSize: $batchSize, windowSize: $windowSize, numberOfFeatures: $numberOfFeatures, inputDataType: $inputDataType, temporalConsistencyEnforcements: $temporalConsistencyEnforcements, stepSize: $stepSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MlModelConfigImpl &&
            (identical(other.enableTeacherForcing, enableTeacherForcing) ||
                other.enableTeacherForcing == enableTeacherForcing) &&
            (identical(other.batchSize, batchSize) ||
                other.batchSize == batchSize) &&
            (identical(other.windowSize, windowSize) ||
                other.windowSize == windowSize) &&
            (identical(other.numberOfFeatures, numberOfFeatures) ||
                other.numberOfFeatures == numberOfFeatures) &&
            (identical(other.inputDataType, inputDataType) ||
                other.inputDataType == inputDataType) &&
            const DeepCollectionEquality().equals(
                other._temporalConsistencyEnforcements,
                _temporalConsistencyEnforcements) &&
            (identical(other.stepSize, stepSize) ||
                other.stepSize == stepSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      enableTeacherForcing,
      batchSize,
      windowSize,
      numberOfFeatures,
      inputDataType,
      const DeepCollectionEquality().hash(_temporalConsistencyEnforcements),
      stepSize);

  /// Create a copy of MlModelConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MlModelConfigImplCopyWith<_$MlModelConfigImpl> get copyWith =>
      __$$MlModelConfigImplCopyWithImpl<_$MlModelConfigImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_MlModelConfig value) $default,
  ) {
    return $default(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_MlModelConfig value)? $default,
  ) {
    return $default?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_MlModelConfig value)? $default, {
    required TResult orElse(),
  }) {
    if ($default != null) {
      return $default(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$MlModelConfigImplToJson(
      this,
    );
  }
}

abstract class _MlModelConfig implements MlModelConfig {
  const factory _MlModelConfig(
      {required final bool enableTeacherForcing,
      required final int batchSize,
      required final int windowSize,
      required final int numberOfFeatures,
      required final InputDataType inputDataType,
      required final Set<TemporalConsistencyEnforcement>
          temporalConsistencyEnforcements,
      final int stepSize}) = _$MlModelConfigImpl;

  factory _MlModelConfig.fromJson(Map<String, dynamic> json) =
      _$MlModelConfigImpl.fromJson;

  @override
  bool get enableTeacherForcing;
  @override
  int get batchSize;
  @override
  int get windowSize;
  @override
  int get numberOfFeatures;
  @override
  InputDataType get inputDataType; // required Set<Smoothing> smoothings,
// required Set<Filtering> filterings,
  Set<TemporalConsistencyEnforcement> get temporalConsistencyEnforcements;
  @override // @Default({}) Set<Weighting> weightings,
  int get stepSize;

  /// Create a copy of MlModelConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MlModelConfigImplCopyWith<_$MlModelConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
