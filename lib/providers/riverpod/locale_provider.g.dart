// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$iraqiHash() => r'c1e776ca314fce7b9a970f247e3f169db59bc146';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [iraqi].
@ProviderFor(iraqi)
const iraqiProvider = IraqiFamily();

/// See also [iraqi].
class IraqiFamily extends Family<String> {
  /// See also [iraqi].
  const IraqiFamily();

  /// See also [iraqi].
  IraqiProvider call(String key) {
    return IraqiProvider(key);
  }

  @override
  IraqiProvider getProviderOverride(covariant IraqiProvider provider) {
    return call(provider.key);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'iraqiProvider';
}

/// See also [iraqi].
class IraqiProvider extends AutoDisposeProvider<String> {
  /// See also [iraqi].
  IraqiProvider(String key)
    : this._internal(
        (ref) => iraqi(ref as IraqiRef, key),
        from: iraqiProvider,
        name: r'iraqiProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$iraqiHash,
        dependencies: IraqiFamily._dependencies,
        allTransitiveDependencies: IraqiFamily._allTransitiveDependencies,
        key: key,
      );

  IraqiProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
  }) : super.internal();

  final String key;

  @override
  Override overrideWith(String Function(IraqiRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: IraqiProvider._internal(
        (ref) => create(ref as IraqiRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _IraqiProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IraqiProvider && other.key == key;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IraqiRef on AutoDisposeProviderRef<String> {
  /// The parameter `key` of this provider.
  String get key;
}

class _IraqiProviderElement extends AutoDisposeProviderElement<String>
    with IraqiRef {
  _IraqiProviderElement(super.provider);

  @override
  String get key => (origin as IraqiProvider).key;
}

String _$textDirectionHash() => r'ab5a1a7b27e59cf224a2783c970a1b31d510db70';

/// See also [textDirection].
@ProviderFor(textDirection)
final textDirectionProvider = AutoDisposeProvider<TextDirection>.internal(
  textDirection,
  name: r'textDirectionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$textDirectionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TextDirectionRef = AutoDisposeProviderRef<TextDirection>;
String _$isRTLHash() => r'ab34385c50928b4d61841a195da4c4fc8e6ef2bd';

/// See also [isRTL].
@ProviderFor(isRTL)
final isRTLProvider = AutoDisposeProvider<bool>.internal(
  isRTL,
  name: r'isRTLProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isRTLHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsRTLRef = AutoDisposeProviderRef<bool>;
String _$supportedLocalesHash() => r'd565599c4fdc802fb36edae0a72fb2c27758da64';

/// See also [supportedLocales].
@ProviderFor(supportedLocales)
final supportedLocalesProvider = AutoDisposeProvider<List<Locale>>.internal(
  supportedLocales,
  name: r'supportedLocalesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supportedLocalesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupportedLocalesRef = AutoDisposeProviderRef<List<Locale>>;
String _$languageNameHash() => r'8120b36f044e9caefc7429cb89cb8644643d1907';

/// See also [languageName].
@ProviderFor(languageName)
const languageNameProvider = LanguageNameFamily();

/// See also [languageName].
class LanguageNameFamily extends Family<String> {
  /// See also [languageName].
  const LanguageNameFamily();

  /// See also [languageName].
  LanguageNameProvider call(String languageCode) {
    return LanguageNameProvider(languageCode);
  }

  @override
  LanguageNameProvider getProviderOverride(
    covariant LanguageNameProvider provider,
  ) {
    return call(provider.languageCode);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'languageNameProvider';
}

/// See also [languageName].
class LanguageNameProvider extends AutoDisposeProvider<String> {
  /// See also [languageName].
  LanguageNameProvider(String languageCode)
    : this._internal(
        (ref) => languageName(ref as LanguageNameRef, languageCode),
        from: languageNameProvider,
        name: r'languageNameProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$languageNameHash,
        dependencies: LanguageNameFamily._dependencies,
        allTransitiveDependencies:
            LanguageNameFamily._allTransitiveDependencies,
        languageCode: languageCode,
      );

  LanguageNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.languageCode,
  }) : super.internal();

  final String languageCode;

  @override
  Override overrideWith(String Function(LanguageNameRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: LanguageNameProvider._internal(
        (ref) => create(ref as LanguageNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        languageCode: languageCode,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _LanguageNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LanguageNameProvider && other.languageCode == languageCode;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, languageCode.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LanguageNameRef on AutoDisposeProviderRef<String> {
  /// The parameter `languageCode` of this provider.
  String get languageCode;
}

class _LanguageNameProviderElement extends AutoDisposeProviderElement<String>
    with LanguageNameRef {
  _LanguageNameProviderElement(super.provider);

  @override
  String get languageCode => (origin as LanguageNameProvider).languageCode;
}

String _$localeNotifierHash() => r'4ec914cb009f505357f07aab0b032828d9d1c568';

/// See also [LocaleNotifier].
@ProviderFor(LocaleNotifier)
final localeNotifierProvider =
    NotifierProvider<LocaleNotifier, Locale>.internal(
      LocaleNotifier.new,
      name: r'localeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$localeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LocaleNotifier = Notifier<Locale>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
