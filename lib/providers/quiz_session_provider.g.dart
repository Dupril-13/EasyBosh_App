// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuizSession)
const quizSessionProvider = QuizSessionProvider._();

final class QuizSessionProvider
    extends $NotifierProvider<QuizSession, QuizSessionState> {
  const QuizSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quizSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quizSessionHash();

  @$internal
  @override
  QuizSession create() => QuizSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuizSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuizSessionState>(value),
    );
  }
}

String _$quizSessionHash() => r'aa7d82a6409f3b502589a2589b6667e10480f05c';

abstract class _$QuizSession extends $Notifier<QuizSessionState> {
  QuizSessionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<QuizSessionState, QuizSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuizSessionState, QuizSessionState>,
              QuizSessionState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
