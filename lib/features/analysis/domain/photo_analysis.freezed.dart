// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_analysis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PhotoAnalysisResponse {

 ColorAnalysis get colorAnalysis; CompositionAnalysis get compositionAnalysis; ToneReport get toneReport; List<String> get shootingTips; List<String> get editingTips; int get overallScore; List<String> get hashtags;
/// Create a copy of PhotoAnalysisResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhotoAnalysisResponseCopyWith<PhotoAnalysisResponse> get copyWith => _$PhotoAnalysisResponseCopyWithImpl<PhotoAnalysisResponse>(this as PhotoAnalysisResponse, _$identity);

  /// Serializes this PhotoAnalysisResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PhotoAnalysisResponse&&(identical(other.colorAnalysis, colorAnalysis) || other.colorAnalysis == colorAnalysis)&&(identical(other.compositionAnalysis, compositionAnalysis) || other.compositionAnalysis == compositionAnalysis)&&(identical(other.toneReport, toneReport) || other.toneReport == toneReport)&&const DeepCollectionEquality().equals(other.shootingTips, shootingTips)&&const DeepCollectionEquality().equals(other.editingTips, editingTips)&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&const DeepCollectionEquality().equals(other.hashtags, hashtags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,colorAnalysis,compositionAnalysis,toneReport,const DeepCollectionEquality().hash(shootingTips),const DeepCollectionEquality().hash(editingTips),overallScore,const DeepCollectionEquality().hash(hashtags));

@override
String toString() {
  return 'PhotoAnalysisResponse(colorAnalysis: $colorAnalysis, compositionAnalysis: $compositionAnalysis, toneReport: $toneReport, shootingTips: $shootingTips, editingTips: $editingTips, overallScore: $overallScore, hashtags: $hashtags)';
}


}

/// @nodoc
abstract mixin class $PhotoAnalysisResponseCopyWith<$Res>  {
  factory $PhotoAnalysisResponseCopyWith(PhotoAnalysisResponse value, $Res Function(PhotoAnalysisResponse) _then) = _$PhotoAnalysisResponseCopyWithImpl;
@useResult
$Res call({
 ColorAnalysis colorAnalysis, CompositionAnalysis compositionAnalysis, ToneReport toneReport, List<String> shootingTips, List<String> editingTips, int overallScore, List<String> hashtags
});


$ColorAnalysisCopyWith<$Res> get colorAnalysis;$CompositionAnalysisCopyWith<$Res> get compositionAnalysis;$ToneReportCopyWith<$Res> get toneReport;

}
/// @nodoc
class _$PhotoAnalysisResponseCopyWithImpl<$Res>
    implements $PhotoAnalysisResponseCopyWith<$Res> {
  _$PhotoAnalysisResponseCopyWithImpl(this._self, this._then);

  final PhotoAnalysisResponse _self;
  final $Res Function(PhotoAnalysisResponse) _then;

/// Create a copy of PhotoAnalysisResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? colorAnalysis = null,Object? compositionAnalysis = null,Object? toneReport = null,Object? shootingTips = null,Object? editingTips = null,Object? overallScore = null,Object? hashtags = null,}) {
  return _then(_self.copyWith(
colorAnalysis: null == colorAnalysis ? _self.colorAnalysis : colorAnalysis // ignore: cast_nullable_to_non_nullable
as ColorAnalysis,compositionAnalysis: null == compositionAnalysis ? _self.compositionAnalysis : compositionAnalysis // ignore: cast_nullable_to_non_nullable
as CompositionAnalysis,toneReport: null == toneReport ? _self.toneReport : toneReport // ignore: cast_nullable_to_non_nullable
as ToneReport,shootingTips: null == shootingTips ? _self.shootingTips : shootingTips // ignore: cast_nullable_to_non_nullable
as List<String>,editingTips: null == editingTips ? _self.editingTips : editingTips // ignore: cast_nullable_to_non_nullable
as List<String>,overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as int,hashtags: null == hashtags ? _self.hashtags : hashtags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of PhotoAnalysisResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ColorAnalysisCopyWith<$Res> get colorAnalysis {
  
  return $ColorAnalysisCopyWith<$Res>(_self.colorAnalysis, (value) {
    return _then(_self.copyWith(colorAnalysis: value));
  });
}/// Create a copy of PhotoAnalysisResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompositionAnalysisCopyWith<$Res> get compositionAnalysis {
  
  return $CompositionAnalysisCopyWith<$Res>(_self.compositionAnalysis, (value) {
    return _then(_self.copyWith(compositionAnalysis: value));
  });
}/// Create a copy of PhotoAnalysisResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToneReportCopyWith<$Res> get toneReport {
  
  return $ToneReportCopyWith<$Res>(_self.toneReport, (value) {
    return _then(_self.copyWith(toneReport: value));
  });
}
}


/// Adds pattern-matching-related methods to [PhotoAnalysisResponse].
extension PhotoAnalysisResponsePatterns on PhotoAnalysisResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PhotoAnalysisResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PhotoAnalysisResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PhotoAnalysisResponse value)  $default,){
final _that = this;
switch (_that) {
case _PhotoAnalysisResponse():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PhotoAnalysisResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PhotoAnalysisResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ColorAnalysis colorAnalysis,  CompositionAnalysis compositionAnalysis,  ToneReport toneReport,  List<String> shootingTips,  List<String> editingTips,  int overallScore,  List<String> hashtags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PhotoAnalysisResponse() when $default != null:
return $default(_that.colorAnalysis,_that.compositionAnalysis,_that.toneReport,_that.shootingTips,_that.editingTips,_that.overallScore,_that.hashtags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ColorAnalysis colorAnalysis,  CompositionAnalysis compositionAnalysis,  ToneReport toneReport,  List<String> shootingTips,  List<String> editingTips,  int overallScore,  List<String> hashtags)  $default,) {final _that = this;
switch (_that) {
case _PhotoAnalysisResponse():
return $default(_that.colorAnalysis,_that.compositionAnalysis,_that.toneReport,_that.shootingTips,_that.editingTips,_that.overallScore,_that.hashtags);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ColorAnalysis colorAnalysis,  CompositionAnalysis compositionAnalysis,  ToneReport toneReport,  List<String> shootingTips,  List<String> editingTips,  int overallScore,  List<String> hashtags)?  $default,) {final _that = this;
switch (_that) {
case _PhotoAnalysisResponse() when $default != null:
return $default(_that.colorAnalysis,_that.compositionAnalysis,_that.toneReport,_that.shootingTips,_that.editingTips,_that.overallScore,_that.hashtags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PhotoAnalysisResponse implements PhotoAnalysisResponse {
  const _PhotoAnalysisResponse({required this.colorAnalysis, required this.compositionAnalysis, required this.toneReport, required final  List<String> shootingTips, required final  List<String> editingTips, required this.overallScore, final  List<String> hashtags = const []}): _shootingTips = shootingTips,_editingTips = editingTips,_hashtags = hashtags;
  factory _PhotoAnalysisResponse.fromJson(Map<String, dynamic> json) => _$PhotoAnalysisResponseFromJson(json);

@override final  ColorAnalysis colorAnalysis;
@override final  CompositionAnalysis compositionAnalysis;
@override final  ToneReport toneReport;
 final  List<String> _shootingTips;
@override List<String> get shootingTips {
  if (_shootingTips is EqualUnmodifiableListView) return _shootingTips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shootingTips);
}

 final  List<String> _editingTips;
@override List<String> get editingTips {
  if (_editingTips is EqualUnmodifiableListView) return _editingTips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_editingTips);
}

@override final  int overallScore;
 final  List<String> _hashtags;
@override@JsonKey() List<String> get hashtags {
  if (_hashtags is EqualUnmodifiableListView) return _hashtags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hashtags);
}


/// Create a copy of PhotoAnalysisResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhotoAnalysisResponseCopyWith<_PhotoAnalysisResponse> get copyWith => __$PhotoAnalysisResponseCopyWithImpl<_PhotoAnalysisResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PhotoAnalysisResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhotoAnalysisResponse&&(identical(other.colorAnalysis, colorAnalysis) || other.colorAnalysis == colorAnalysis)&&(identical(other.compositionAnalysis, compositionAnalysis) || other.compositionAnalysis == compositionAnalysis)&&(identical(other.toneReport, toneReport) || other.toneReport == toneReport)&&const DeepCollectionEquality().equals(other._shootingTips, _shootingTips)&&const DeepCollectionEquality().equals(other._editingTips, _editingTips)&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&const DeepCollectionEquality().equals(other._hashtags, _hashtags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,colorAnalysis,compositionAnalysis,toneReport,const DeepCollectionEquality().hash(_shootingTips),const DeepCollectionEquality().hash(_editingTips),overallScore,const DeepCollectionEquality().hash(_hashtags));

@override
String toString() {
  return 'PhotoAnalysisResponse(colorAnalysis: $colorAnalysis, compositionAnalysis: $compositionAnalysis, toneReport: $toneReport, shootingTips: $shootingTips, editingTips: $editingTips, overallScore: $overallScore, hashtags: $hashtags)';
}


}

/// @nodoc
abstract mixin class _$PhotoAnalysisResponseCopyWith<$Res> implements $PhotoAnalysisResponseCopyWith<$Res> {
  factory _$PhotoAnalysisResponseCopyWith(_PhotoAnalysisResponse value, $Res Function(_PhotoAnalysisResponse) _then) = __$PhotoAnalysisResponseCopyWithImpl;
@override @useResult
$Res call({
 ColorAnalysis colorAnalysis, CompositionAnalysis compositionAnalysis, ToneReport toneReport, List<String> shootingTips, List<String> editingTips, int overallScore, List<String> hashtags
});


@override $ColorAnalysisCopyWith<$Res> get colorAnalysis;@override $CompositionAnalysisCopyWith<$Res> get compositionAnalysis;@override $ToneReportCopyWith<$Res> get toneReport;

}
/// @nodoc
class __$PhotoAnalysisResponseCopyWithImpl<$Res>
    implements _$PhotoAnalysisResponseCopyWith<$Res> {
  __$PhotoAnalysisResponseCopyWithImpl(this._self, this._then);

  final _PhotoAnalysisResponse _self;
  final $Res Function(_PhotoAnalysisResponse) _then;

/// Create a copy of PhotoAnalysisResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? colorAnalysis = null,Object? compositionAnalysis = null,Object? toneReport = null,Object? shootingTips = null,Object? editingTips = null,Object? overallScore = null,Object? hashtags = null,}) {
  return _then(_PhotoAnalysisResponse(
colorAnalysis: null == colorAnalysis ? _self.colorAnalysis : colorAnalysis // ignore: cast_nullable_to_non_nullable
as ColorAnalysis,compositionAnalysis: null == compositionAnalysis ? _self.compositionAnalysis : compositionAnalysis // ignore: cast_nullable_to_non_nullable
as CompositionAnalysis,toneReport: null == toneReport ? _self.toneReport : toneReport // ignore: cast_nullable_to_non_nullable
as ToneReport,shootingTips: null == shootingTips ? _self._shootingTips : shootingTips // ignore: cast_nullable_to_non_nullable
as List<String>,editingTips: null == editingTips ? _self._editingTips : editingTips // ignore: cast_nullable_to_non_nullable
as List<String>,overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as int,hashtags: null == hashtags ? _self._hashtags : hashtags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of PhotoAnalysisResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ColorAnalysisCopyWith<$Res> get colorAnalysis {
  
  return $ColorAnalysisCopyWith<$Res>(_self.colorAnalysis, (value) {
    return _then(_self.copyWith(colorAnalysis: value));
  });
}/// Create a copy of PhotoAnalysisResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompositionAnalysisCopyWith<$Res> get compositionAnalysis {
  
  return $CompositionAnalysisCopyWith<$Res>(_self.compositionAnalysis, (value) {
    return _then(_self.copyWith(compositionAnalysis: value));
  });
}/// Create a copy of PhotoAnalysisResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToneReportCopyWith<$Res> get toneReport {
  
  return $ToneReportCopyWith<$Res>(_self.toneReport, (value) {
    return _then(_self.copyWith(toneReport: value));
  });
}
}


/// @nodoc
mixin _$ColorAnalysis {

 List<String> get dominantColors; String get colorTemperature; double get saturationLevel; double get brightnessLevel; String get colorHarmony; String get paletteDescription;
/// Create a copy of ColorAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColorAnalysisCopyWith<ColorAnalysis> get copyWith => _$ColorAnalysisCopyWithImpl<ColorAnalysis>(this as ColorAnalysis, _$identity);

  /// Serializes this ColorAnalysis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ColorAnalysis&&const DeepCollectionEquality().equals(other.dominantColors, dominantColors)&&(identical(other.colorTemperature, colorTemperature) || other.colorTemperature == colorTemperature)&&(identical(other.saturationLevel, saturationLevel) || other.saturationLevel == saturationLevel)&&(identical(other.brightnessLevel, brightnessLevel) || other.brightnessLevel == brightnessLevel)&&(identical(other.colorHarmony, colorHarmony) || other.colorHarmony == colorHarmony)&&(identical(other.paletteDescription, paletteDescription) || other.paletteDescription == paletteDescription));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(dominantColors),colorTemperature,saturationLevel,brightnessLevel,colorHarmony,paletteDescription);

@override
String toString() {
  return 'ColorAnalysis(dominantColors: $dominantColors, colorTemperature: $colorTemperature, saturationLevel: $saturationLevel, brightnessLevel: $brightnessLevel, colorHarmony: $colorHarmony, paletteDescription: $paletteDescription)';
}


}

/// @nodoc
abstract mixin class $ColorAnalysisCopyWith<$Res>  {
  factory $ColorAnalysisCopyWith(ColorAnalysis value, $Res Function(ColorAnalysis) _then) = _$ColorAnalysisCopyWithImpl;
@useResult
$Res call({
 List<String> dominantColors, String colorTemperature, double saturationLevel, double brightnessLevel, String colorHarmony, String paletteDescription
});




}
/// @nodoc
class _$ColorAnalysisCopyWithImpl<$Res>
    implements $ColorAnalysisCopyWith<$Res> {
  _$ColorAnalysisCopyWithImpl(this._self, this._then);

  final ColorAnalysis _self;
  final $Res Function(ColorAnalysis) _then;

/// Create a copy of ColorAnalysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dominantColors = null,Object? colorTemperature = null,Object? saturationLevel = null,Object? brightnessLevel = null,Object? colorHarmony = null,Object? paletteDescription = null,}) {
  return _then(_self.copyWith(
dominantColors: null == dominantColors ? _self.dominantColors : dominantColors // ignore: cast_nullable_to_non_nullable
as List<String>,colorTemperature: null == colorTemperature ? _self.colorTemperature : colorTemperature // ignore: cast_nullable_to_non_nullable
as String,saturationLevel: null == saturationLevel ? _self.saturationLevel : saturationLevel // ignore: cast_nullable_to_non_nullable
as double,brightnessLevel: null == brightnessLevel ? _self.brightnessLevel : brightnessLevel // ignore: cast_nullable_to_non_nullable
as double,colorHarmony: null == colorHarmony ? _self.colorHarmony : colorHarmony // ignore: cast_nullable_to_non_nullable
as String,paletteDescription: null == paletteDescription ? _self.paletteDescription : paletteDescription // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ColorAnalysis].
extension ColorAnalysisPatterns on ColorAnalysis {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ColorAnalysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ColorAnalysis() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ColorAnalysis value)  $default,){
final _that = this;
switch (_that) {
case _ColorAnalysis():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ColorAnalysis value)?  $default,){
final _that = this;
switch (_that) {
case _ColorAnalysis() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> dominantColors,  String colorTemperature,  double saturationLevel,  double brightnessLevel,  String colorHarmony,  String paletteDescription)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ColorAnalysis() when $default != null:
return $default(_that.dominantColors,_that.colorTemperature,_that.saturationLevel,_that.brightnessLevel,_that.colorHarmony,_that.paletteDescription);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> dominantColors,  String colorTemperature,  double saturationLevel,  double brightnessLevel,  String colorHarmony,  String paletteDescription)  $default,) {final _that = this;
switch (_that) {
case _ColorAnalysis():
return $default(_that.dominantColors,_that.colorTemperature,_that.saturationLevel,_that.brightnessLevel,_that.colorHarmony,_that.paletteDescription);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> dominantColors,  String colorTemperature,  double saturationLevel,  double brightnessLevel,  String colorHarmony,  String paletteDescription)?  $default,) {final _that = this;
switch (_that) {
case _ColorAnalysis() when $default != null:
return $default(_that.dominantColors,_that.colorTemperature,_that.saturationLevel,_that.brightnessLevel,_that.colorHarmony,_that.paletteDescription);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ColorAnalysis implements ColorAnalysis {
  const _ColorAnalysis({required final  List<String> dominantColors, required this.colorTemperature, required this.saturationLevel, required this.brightnessLevel, required this.colorHarmony, required this.paletteDescription}): _dominantColors = dominantColors;
  factory _ColorAnalysis.fromJson(Map<String, dynamic> json) => _$ColorAnalysisFromJson(json);

 final  List<String> _dominantColors;
@override List<String> get dominantColors {
  if (_dominantColors is EqualUnmodifiableListView) return _dominantColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dominantColors);
}

@override final  String colorTemperature;
@override final  double saturationLevel;
@override final  double brightnessLevel;
@override final  String colorHarmony;
@override final  String paletteDescription;

/// Create a copy of ColorAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ColorAnalysisCopyWith<_ColorAnalysis> get copyWith => __$ColorAnalysisCopyWithImpl<_ColorAnalysis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ColorAnalysisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ColorAnalysis&&const DeepCollectionEquality().equals(other._dominantColors, _dominantColors)&&(identical(other.colorTemperature, colorTemperature) || other.colorTemperature == colorTemperature)&&(identical(other.saturationLevel, saturationLevel) || other.saturationLevel == saturationLevel)&&(identical(other.brightnessLevel, brightnessLevel) || other.brightnessLevel == brightnessLevel)&&(identical(other.colorHarmony, colorHarmony) || other.colorHarmony == colorHarmony)&&(identical(other.paletteDescription, paletteDescription) || other.paletteDescription == paletteDescription));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_dominantColors),colorTemperature,saturationLevel,brightnessLevel,colorHarmony,paletteDescription);

@override
String toString() {
  return 'ColorAnalysis(dominantColors: $dominantColors, colorTemperature: $colorTemperature, saturationLevel: $saturationLevel, brightnessLevel: $brightnessLevel, colorHarmony: $colorHarmony, paletteDescription: $paletteDescription)';
}


}

/// @nodoc
abstract mixin class _$ColorAnalysisCopyWith<$Res> implements $ColorAnalysisCopyWith<$Res> {
  factory _$ColorAnalysisCopyWith(_ColorAnalysis value, $Res Function(_ColorAnalysis) _then) = __$ColorAnalysisCopyWithImpl;
@override @useResult
$Res call({
 List<String> dominantColors, String colorTemperature, double saturationLevel, double brightnessLevel, String colorHarmony, String paletteDescription
});




}
/// @nodoc
class __$ColorAnalysisCopyWithImpl<$Res>
    implements _$ColorAnalysisCopyWith<$Res> {
  __$ColorAnalysisCopyWithImpl(this._self, this._then);

  final _ColorAnalysis _self;
  final $Res Function(_ColorAnalysis) _then;

/// Create a copy of ColorAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dominantColors = null,Object? colorTemperature = null,Object? saturationLevel = null,Object? brightnessLevel = null,Object? colorHarmony = null,Object? paletteDescription = null,}) {
  return _then(_ColorAnalysis(
dominantColors: null == dominantColors ? _self._dominantColors : dominantColors // ignore: cast_nullable_to_non_nullable
as List<String>,colorTemperature: null == colorTemperature ? _self.colorTemperature : colorTemperature // ignore: cast_nullable_to_non_nullable
as String,saturationLevel: null == saturationLevel ? _self.saturationLevel : saturationLevel // ignore: cast_nullable_to_non_nullable
as double,brightnessLevel: null == brightnessLevel ? _self.brightnessLevel : brightnessLevel // ignore: cast_nullable_to_non_nullable
as double,colorHarmony: null == colorHarmony ? _self.colorHarmony : colorHarmony // ignore: cast_nullable_to_non_nullable
as String,paletteDescription: null == paletteDescription ? _self.paletteDescription : paletteDescription // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CompositionAnalysis {

 String get primaryTechnique; double get balanceScore; List<String> get strengths; List<String> get improvements;
/// Create a copy of CompositionAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompositionAnalysisCopyWith<CompositionAnalysis> get copyWith => _$CompositionAnalysisCopyWithImpl<CompositionAnalysis>(this as CompositionAnalysis, _$identity);

  /// Serializes this CompositionAnalysis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompositionAnalysis&&(identical(other.primaryTechnique, primaryTechnique) || other.primaryTechnique == primaryTechnique)&&(identical(other.balanceScore, balanceScore) || other.balanceScore == balanceScore)&&const DeepCollectionEquality().equals(other.strengths, strengths)&&const DeepCollectionEquality().equals(other.improvements, improvements));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,primaryTechnique,balanceScore,const DeepCollectionEquality().hash(strengths),const DeepCollectionEquality().hash(improvements));

@override
String toString() {
  return 'CompositionAnalysis(primaryTechnique: $primaryTechnique, balanceScore: $balanceScore, strengths: $strengths, improvements: $improvements)';
}


}

/// @nodoc
abstract mixin class $CompositionAnalysisCopyWith<$Res>  {
  factory $CompositionAnalysisCopyWith(CompositionAnalysis value, $Res Function(CompositionAnalysis) _then) = _$CompositionAnalysisCopyWithImpl;
@useResult
$Res call({
 String primaryTechnique, double balanceScore, List<String> strengths, List<String> improvements
});




}
/// @nodoc
class _$CompositionAnalysisCopyWithImpl<$Res>
    implements $CompositionAnalysisCopyWith<$Res> {
  _$CompositionAnalysisCopyWithImpl(this._self, this._then);

  final CompositionAnalysis _self;
  final $Res Function(CompositionAnalysis) _then;

/// Create a copy of CompositionAnalysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primaryTechnique = null,Object? balanceScore = null,Object? strengths = null,Object? improvements = null,}) {
  return _then(_self.copyWith(
primaryTechnique: null == primaryTechnique ? _self.primaryTechnique : primaryTechnique // ignore: cast_nullable_to_non_nullable
as String,balanceScore: null == balanceScore ? _self.balanceScore : balanceScore // ignore: cast_nullable_to_non_nullable
as double,strengths: null == strengths ? _self.strengths : strengths // ignore: cast_nullable_to_non_nullable
as List<String>,improvements: null == improvements ? _self.improvements : improvements // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CompositionAnalysis].
extension CompositionAnalysisPatterns on CompositionAnalysis {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompositionAnalysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompositionAnalysis() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompositionAnalysis value)  $default,){
final _that = this;
switch (_that) {
case _CompositionAnalysis():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompositionAnalysis value)?  $default,){
final _that = this;
switch (_that) {
case _CompositionAnalysis() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String primaryTechnique,  double balanceScore,  List<String> strengths,  List<String> improvements)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompositionAnalysis() when $default != null:
return $default(_that.primaryTechnique,_that.balanceScore,_that.strengths,_that.improvements);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String primaryTechnique,  double balanceScore,  List<String> strengths,  List<String> improvements)  $default,) {final _that = this;
switch (_that) {
case _CompositionAnalysis():
return $default(_that.primaryTechnique,_that.balanceScore,_that.strengths,_that.improvements);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String primaryTechnique,  double balanceScore,  List<String> strengths,  List<String> improvements)?  $default,) {final _that = this;
switch (_that) {
case _CompositionAnalysis() when $default != null:
return $default(_that.primaryTechnique,_that.balanceScore,_that.strengths,_that.improvements);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompositionAnalysis implements CompositionAnalysis {
  const _CompositionAnalysis({required this.primaryTechnique, required this.balanceScore, required final  List<String> strengths, required final  List<String> improvements}): _strengths = strengths,_improvements = improvements;
  factory _CompositionAnalysis.fromJson(Map<String, dynamic> json) => _$CompositionAnalysisFromJson(json);

@override final  String primaryTechnique;
@override final  double balanceScore;
 final  List<String> _strengths;
@override List<String> get strengths {
  if (_strengths is EqualUnmodifiableListView) return _strengths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_strengths);
}

 final  List<String> _improvements;
@override List<String> get improvements {
  if (_improvements is EqualUnmodifiableListView) return _improvements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_improvements);
}


/// Create a copy of CompositionAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompositionAnalysisCopyWith<_CompositionAnalysis> get copyWith => __$CompositionAnalysisCopyWithImpl<_CompositionAnalysis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompositionAnalysisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompositionAnalysis&&(identical(other.primaryTechnique, primaryTechnique) || other.primaryTechnique == primaryTechnique)&&(identical(other.balanceScore, balanceScore) || other.balanceScore == balanceScore)&&const DeepCollectionEquality().equals(other._strengths, _strengths)&&const DeepCollectionEquality().equals(other._improvements, _improvements));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,primaryTechnique,balanceScore,const DeepCollectionEquality().hash(_strengths),const DeepCollectionEquality().hash(_improvements));

@override
String toString() {
  return 'CompositionAnalysis(primaryTechnique: $primaryTechnique, balanceScore: $balanceScore, strengths: $strengths, improvements: $improvements)';
}


}

/// @nodoc
abstract mixin class _$CompositionAnalysisCopyWith<$Res> implements $CompositionAnalysisCopyWith<$Res> {
  factory _$CompositionAnalysisCopyWith(_CompositionAnalysis value, $Res Function(_CompositionAnalysis) _then) = __$CompositionAnalysisCopyWithImpl;
@override @useResult
$Res call({
 String primaryTechnique, double balanceScore, List<String> strengths, List<String> improvements
});




}
/// @nodoc
class __$CompositionAnalysisCopyWithImpl<$Res>
    implements _$CompositionAnalysisCopyWith<$Res> {
  __$CompositionAnalysisCopyWithImpl(this._self, this._then);

  final _CompositionAnalysis _self;
  final $Res Function(_CompositionAnalysis) _then;

/// Create a copy of CompositionAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? primaryTechnique = null,Object? balanceScore = null,Object? strengths = null,Object? improvements = null,}) {
  return _then(_CompositionAnalysis(
primaryTechnique: null == primaryTechnique ? _self.primaryTechnique : primaryTechnique // ignore: cast_nullable_to_non_nullable
as String,balanceScore: null == balanceScore ? _self.balanceScore : balanceScore // ignore: cast_nullable_to_non_nullable
as double,strengths: null == strengths ? _self._strengths : strengths // ignore: cast_nullable_to_non_nullable
as List<String>,improvements: null == improvements ? _self._improvements : improvements // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ToneReport {

 String get overallMood; String get styleCategory; String get narrative;
/// Create a copy of ToneReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToneReportCopyWith<ToneReport> get copyWith => _$ToneReportCopyWithImpl<ToneReport>(this as ToneReport, _$identity);

  /// Serializes this ToneReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToneReport&&(identical(other.overallMood, overallMood) || other.overallMood == overallMood)&&(identical(other.styleCategory, styleCategory) || other.styleCategory == styleCategory)&&(identical(other.narrative, narrative) || other.narrative == narrative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overallMood,styleCategory,narrative);

@override
String toString() {
  return 'ToneReport(overallMood: $overallMood, styleCategory: $styleCategory, narrative: $narrative)';
}


}

/// @nodoc
abstract mixin class $ToneReportCopyWith<$Res>  {
  factory $ToneReportCopyWith(ToneReport value, $Res Function(ToneReport) _then) = _$ToneReportCopyWithImpl;
@useResult
$Res call({
 String overallMood, String styleCategory, String narrative
});




}
/// @nodoc
class _$ToneReportCopyWithImpl<$Res>
    implements $ToneReportCopyWith<$Res> {
  _$ToneReportCopyWithImpl(this._self, this._then);

  final ToneReport _self;
  final $Res Function(ToneReport) _then;

/// Create a copy of ToneReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overallMood = null,Object? styleCategory = null,Object? narrative = null,}) {
  return _then(_self.copyWith(
overallMood: null == overallMood ? _self.overallMood : overallMood // ignore: cast_nullable_to_non_nullable
as String,styleCategory: null == styleCategory ? _self.styleCategory : styleCategory // ignore: cast_nullable_to_non_nullable
as String,narrative: null == narrative ? _self.narrative : narrative // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ToneReport].
extension ToneReportPatterns on ToneReport {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToneReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToneReport() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToneReport value)  $default,){
final _that = this;
switch (_that) {
case _ToneReport():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToneReport value)?  $default,){
final _that = this;
switch (_that) {
case _ToneReport() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String overallMood,  String styleCategory,  String narrative)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToneReport() when $default != null:
return $default(_that.overallMood,_that.styleCategory,_that.narrative);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String overallMood,  String styleCategory,  String narrative)  $default,) {final _that = this;
switch (_that) {
case _ToneReport():
return $default(_that.overallMood,_that.styleCategory,_that.narrative);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String overallMood,  String styleCategory,  String narrative)?  $default,) {final _that = this;
switch (_that) {
case _ToneReport() when $default != null:
return $default(_that.overallMood,_that.styleCategory,_that.narrative);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ToneReport implements ToneReport {
  const _ToneReport({required this.overallMood, required this.styleCategory, required this.narrative});
  factory _ToneReport.fromJson(Map<String, dynamic> json) => _$ToneReportFromJson(json);

@override final  String overallMood;
@override final  String styleCategory;
@override final  String narrative;

/// Create a copy of ToneReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToneReportCopyWith<_ToneReport> get copyWith => __$ToneReportCopyWithImpl<_ToneReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ToneReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToneReport&&(identical(other.overallMood, overallMood) || other.overallMood == overallMood)&&(identical(other.styleCategory, styleCategory) || other.styleCategory == styleCategory)&&(identical(other.narrative, narrative) || other.narrative == narrative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overallMood,styleCategory,narrative);

@override
String toString() {
  return 'ToneReport(overallMood: $overallMood, styleCategory: $styleCategory, narrative: $narrative)';
}


}

/// @nodoc
abstract mixin class _$ToneReportCopyWith<$Res> implements $ToneReportCopyWith<$Res> {
  factory _$ToneReportCopyWith(_ToneReport value, $Res Function(_ToneReport) _then) = __$ToneReportCopyWithImpl;
@override @useResult
$Res call({
 String overallMood, String styleCategory, String narrative
});




}
/// @nodoc
class __$ToneReportCopyWithImpl<$Res>
    implements _$ToneReportCopyWith<$Res> {
  __$ToneReportCopyWithImpl(this._self, this._then);

  final _ToneReport _self;
  final $Res Function(_ToneReport) _then;

/// Create a copy of ToneReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overallMood = null,Object? styleCategory = null,Object? narrative = null,}) {
  return _then(_ToneReport(
overallMood: null == overallMood ? _self.overallMood : overallMood // ignore: cast_nullable_to_non_nullable
as String,styleCategory: null == styleCategory ? _self.styleCategory : styleCategory // ignore: cast_nullable_to_non_nullable
as String,narrative: null == narrative ? _self.narrative : narrative // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
