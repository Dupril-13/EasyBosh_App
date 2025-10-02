// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filters_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(filtersService)
const filtersServiceProvider = FiltersServiceProvider._();

final class FiltersServiceProvider
    extends $FunctionalProvider<FiltersService, FiltersService, FiltersService>
    with $Provider<FiltersService> {
  const FiltersServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filtersServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filtersServiceHash();

  @$internal
  @override
  $ProviderElement<FiltersService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FiltersService create(Ref ref) {
    return filtersService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FiltersService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FiltersService>(value),
    );
  }
}

String _$filtersServiceHash() => r'4a3b2f6ab0a7305bc6a04935cc796824d0550e8a';

@ProviderFor(niveaux)
const niveauxProvider = NiveauxProvider._();

final class NiveauxProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NiveauSelectionItem>>,
          List<NiveauSelectionItem>,
          FutureOr<List<NiveauSelectionItem>>
        >
    with
        $FutureModifier<List<NiveauSelectionItem>>,
        $FutureProvider<List<NiveauSelectionItem>> {
  const NiveauxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'niveauxProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$niveauxHash();

  @$internal
  @override
  $FutureProviderElement<List<NiveauSelectionItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NiveauSelectionItem>> create(Ref ref) {
    return niveaux(ref);
  }
}

String _$niveauxHash() => r'ff1c4ef666bff922cd0474ab92e4d889d5a05937';

@ProviderFor(seriesForSelection)
const seriesForSelectionProvider = SeriesForSelectionProvider._();

final class SeriesForSelectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SerieSelectionItem>>,
          List<SerieSelectionItem>,
          FutureOr<List<SerieSelectionItem>>
        >
    with
        $FutureModifier<List<SerieSelectionItem>>,
        $FutureProvider<List<SerieSelectionItem>> {
  const SeriesForSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seriesForSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seriesForSelectionHash();

  @$internal
  @override
  $FutureProviderElement<List<SerieSelectionItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SerieSelectionItem>> create(Ref ref) {
    return seriesForSelection(ref);
  }
}

String _$seriesForSelectionHash() =>
    r'8cfd573d21573ec52a8d14b4aace3c789a058995';

@ProviderFor(allMatieres)
const allMatieresProvider = AllMatieresProvider._();

final class AllMatieresProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatiereSelectionItem>>,
          List<MatiereSelectionItem>,
          FutureOr<List<MatiereSelectionItem>>
        >
    with
        $FutureModifier<List<MatiereSelectionItem>>,
        $FutureProvider<List<MatiereSelectionItem>> {
  const AllMatieresProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allMatieresProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allMatieresHash();

  @$internal
  @override
  $FutureProviderElement<List<MatiereSelectionItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatiereSelectionItem>> create(Ref ref) {
    return allMatieres(ref);
  }
}

String _$allMatieresHash() => r'7ca78de0e4f945d61e511ea54ecaaf34c76ae3b8';

@ProviderFor(SelectedNiveauCode)
const selectedNiveauCodeProvider = SelectedNiveauCodeProvider._();

final class SelectedNiveauCodeProvider
    extends $NotifierProvider<SelectedNiveauCode, String?> {
  const SelectedNiveauCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedNiveauCodeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedNiveauCodeHash();

  @$internal
  @override
  SelectedNiveauCode create() => SelectedNiveauCode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedNiveauCodeHash() =>
    r'64ffdc59d7e9c752336c1e10c3e7320a1a33e6d1';

abstract class _$SelectedNiveauCode extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(SelectedSeriesCodesForFilter)
const selectedSeriesCodesForFilterProvider =
    SelectedSeriesCodesForFilterProvider._();

final class SelectedSeriesCodesForFilterProvider
    extends $NotifierProvider<SelectedSeriesCodesForFilter, List<String>> {
  const SelectedSeriesCodesForFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSeriesCodesForFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSeriesCodesForFilterHash();

  @$internal
  @override
  SelectedSeriesCodesForFilter create() => SelectedSeriesCodesForFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$selectedSeriesCodesForFilterHash() =>
    r'35222fee20e8042d3c76b59b73d64eb638500e4a';

abstract class _$SelectedSeriesCodesForFilter extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(filteredMatieresList)
const filteredMatieresListProvider = FilteredMatieresListProvider._();

final class FilteredMatieresListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatiereSelectionItem>>,
          List<MatiereSelectionItem>,
          FutureOr<List<MatiereSelectionItem>>
        >
    with
        $FutureModifier<List<MatiereSelectionItem>>,
        $FutureProvider<List<MatiereSelectionItem>> {
  const FilteredMatieresListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredMatieresListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredMatieresListHash();

  @$internal
  @override
  $FutureProviderElement<List<MatiereSelectionItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatiereSelectionItem>> create(Ref ref) {
    return filteredMatieresList(ref);
  }
}

String _$filteredMatieresListHash() =>
    r'fb9f003bb4ee14549d2a9f9d452baf1ad49fca1c';
