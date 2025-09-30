// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lecon_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Lecon)
const leconProvider = LeconProvider._();

final class LeconProvider extends $NotifierProvider<Lecon, LeconState> {
  const LeconProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leconProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leconHash();

  @$internal
  @override
  Lecon create() => Lecon();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeconState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeconState>(value),
    );
  }
}

String _$leconHash() => r'572b04522a2e52b90a5cf3f367a8f776f19ec7e6';

abstract class _$Lecon extends $Notifier<LeconState> {
  LeconState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LeconState, LeconState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeconState, LeconState>,
              LeconState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
