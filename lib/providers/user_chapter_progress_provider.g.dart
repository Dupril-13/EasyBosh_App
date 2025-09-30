// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_chapter_progress_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserChapterProgress)
const userChapterProgressProvider = UserChapterProgressProvider._();

final class UserChapterProgressProvider
    extends $NotifierProvider<UserChapterProgress, UserChapterProgressState> {
  const UserChapterProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userChapterProgressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userChapterProgressHash();

  @$internal
  @override
  UserChapterProgress create() => UserChapterProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserChapterProgressState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserChapterProgressState>(value),
    );
  }
}

String _$userChapterProgressHash() =>
    r'b603dba8f0494b8ff643523aa618c33d7ecbcded';

abstract class _$UserChapterProgress
    extends $Notifier<UserChapterProgressState> {
  UserChapterProgressState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<UserChapterProgressState, UserChapterProgressState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserChapterProgressState, UserChapterProgressState>,
              UserChapterProgressState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
