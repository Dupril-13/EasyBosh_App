// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Course)
const courseProvider = CourseProvider._();

final class CourseProvider extends $NotifierProvider<Course, CourseState> {
  const CourseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courseHash();

  @$internal
  @override
  Course create() => Course();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CourseState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CourseState>(value),
    );
  }
}

String _$courseHash() => r'ac98148de12b3f9c0bc90ba30da05919393ff626';

abstract class _$Course extends $Notifier<CourseState> {
  CourseState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CourseState, CourseState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CourseState, CourseState>,
              CourseState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
