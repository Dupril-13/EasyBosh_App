// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'niveau_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Niveau)
const niveauProvider = NiveauProvider._();

final class NiveauProvider extends $NotifierProvider<Niveau, NiveauState> {
  const NiveauProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'niveauProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$niveauHash();

  @$internal
  @override
  Niveau create() => Niveau();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NiveauState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NiveauState>(value),
    );
  }
}

String _$niveauHash() => r'5ae31b51bdc93b584156d1c0bcb7a241498ee9b1';

abstract class _$Niveau extends $Notifier<NiveauState> {
  NiveauState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<NiveauState, NiveauState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NiveauState, NiveauState>,
              NiveauState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
