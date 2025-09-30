// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapitre_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Chapitre)
const chapitreProvider = ChapitreProvider._();

final class ChapitreProvider
    extends $NotifierProvider<Chapitre, ChapitreState> {
  const ChapitreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chapitreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chapitreHash();

  @$internal
  @override
  Chapitre create() => Chapitre();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChapitreState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChapitreState>(value),
    );
  }
}

String _$chapitreHash() => r'f88de8ee80ceb178248976f72b99ad4f2b5192b3';

abstract class _$Chapitre extends $Notifier<ChapitreState> {
  ChapitreState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ChapitreState, ChapitreState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChapitreState, ChapitreState>,
              ChapitreState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
