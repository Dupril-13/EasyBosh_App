// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serie_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Serie)
const serieProvider = SerieProvider._();

final class SerieProvider extends $NotifierProvider<Serie, SerieState> {
  const SerieProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serieProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serieHash();

  @$internal
  @override
  Serie create() => Serie();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SerieState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SerieState>(value),
    );
  }
}

String _$serieHash() => r'e2bc9ed742386b84f810d48a0398a54802b573f1';

abstract class _$Serie extends $Notifier<SerieState> {
  SerieState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SerieState, SerieState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SerieState, SerieState>,
              SerieState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
