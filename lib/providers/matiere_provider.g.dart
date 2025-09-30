// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matiere_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Matiere)
const matiereProvider = MatiereProvider._();

final class MatiereProvider extends $NotifierProvider<Matiere, MatiereState> {
  const MatiereProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matiereProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matiereHash();

  @$internal
  @override
  Matiere create() => Matiere();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatiereState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatiereState>(value),
    );
  }
}

String _$matiereHash() => r'aeec36725116b41230c79360c955262e0b0d8506';

abstract class _$Matiere extends $Notifier<MatiereState> {
  MatiereState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MatiereState, MatiereState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MatiereState, MatiereState>,
              MatiereState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
