// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_lecons_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecentLecons)
const recentLeconsProvider = RecentLeconsProvider._();

final class RecentLeconsProvider
    extends $NotifierProvider<RecentLecons, RecentLeconsState> {
  const RecentLeconsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentLeconsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentLeconsHash();

  @$internal
  @override
  RecentLecons create() => RecentLecons();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentLeconsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentLeconsState>(value),
    );
  }
}

String _$recentLeconsHash() => r'b60d841732228761217be1680e6b4e5cb62dd9b1';

abstract class _$RecentLecons extends $Notifier<RecentLeconsState> {
  RecentLeconsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<RecentLeconsState, RecentLeconsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecentLeconsState, RecentLeconsState>,
              RecentLeconsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
