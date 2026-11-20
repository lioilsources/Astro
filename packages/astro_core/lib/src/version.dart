/// Version of the engine stored with every journal entry (plan 10.3).
/// Bump together with `version` in pubspec.yaml when results can change.
const engineVersion = '0.1.0';

/// Version of the daily tension formula (`TransitEngine.tensionAt`, docs/scoring.md).
/// Bump whenever the formula changes; journal entries with an older version get
/// their tension recomputed for evaluation.
const tensionFormulaVersion = 1;
