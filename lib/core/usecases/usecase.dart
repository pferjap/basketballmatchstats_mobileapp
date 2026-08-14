/// Base contract for a use case (interactor) in the domain layer.
///
/// A use case encapsulates a single unit of business logic. It is invoked like
/// a function: `await useCase(params)`. Implementations typically delegate to a
/// repository and may throw a `Failure` on error. See Plan.md T-005.
///
/// - [T]: the successful return type.
/// - [Params]: the input parameters. Use [NoParams] when none are required.
abstract interface class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Marker for use cases that take no parameters.
class NoParams {
  const NoParams();

  @override
  bool operator ==(Object other) => other is NoParams;

  @override
  int get hashCode => 0;
}
