import Either
import Foundation
import SQLKit

extension EitherIO where E == Error {
  /// Create a new `EitherIO` from an event loop future.
  public init(_ eventLoopFuture: @escaping @autoclosure () -> EventLoopFuture<A>) {
    self.init(
      run: .init { callback in
        eventLoopFuture()
          .whenComplete { callback(Either(result: $0)) }
      }
    )
  }

  /// Return an `EitherIO` from a closure that can throw errors.
  public static func catching(_ work: @escaping () throws -> EitherIO) -> EitherIO {
    do {
      return try work()
    } catch {
      return .init(run: .init { .left(error) })
    }
  }
}

extension EitherIO where E == Error, A == Void {

  /// Return an `EitherIO` from a closure that can throw errors.
  public static func catching(_ work: @escaping () throws -> Void) -> EitherIO {
    do {
      try work()
      return .init(run: .init { .right(()) })
    } catch {
      return .init(run: .init { .left(error) })
    }
  }
}

extension Either where L: Error {

  /// Convert a `Result` to an `Either` type.
  init(result: Result<R, L>) {
    switch result {
    case let .success(value):
      self = .right(value)
    case let .failure(error):
      self = .left(error)
    }
  }
}

extension SQLDatabase {

  /// Run a raw query on the database. Returning the future as an `EitherIO` type.
  ///
  /// - Parameters:
  ///   - query: The raw query to run on the database.
  public func run(_ query: SQLQueryString) -> EitherIO<Error, Void> {
    EitherIO(self.raw(query).run())
  }
}

extension SQLQueryFetcher {

  /// Wraps the default query in one that returns an `EitherIO` type instead of an `EventloopFuture`.
  ///
  /// - Parameters:
  ///   - decoding: The type to decode from database request.
  public func first<D>(decoding: D.Type) -> EitherIO<Error, D?> where D: Decodable {
    .init(self.first(decoding: D.self))
  }

  /// Wraps the default query in one that returns an `EitherIO` type instead of an `EventloopFuture`.
  ///
  /// - Parameters:
  ///   - decoding: The type to decode from database request.
  public func all<D>(decoding: D.Type) -> EitherIO<Error, [D]> where D: Decodable {
    .init(self.all(decoding: D.self))
  }

  /// Wraps the default query in one that returns an `EitherIO` type instead of an `EventloopFuture`.
  public func run() -> EitherIO<Error, Void> {
    .init(self.run())
  }
}

extension SQLQueryBuilder {

  /// Wraps the default query in one that returns an `EitherIO` type instead of an `EventloopFuture`.
  public func run() -> EitherIO<Error, Void> {
    .init(self.run())
  }
}

extension String {
  /// Convenience used for returning all columns in a database query.
  public static let all = "*"
}

extension EitherIO where E == Error {

  public func unwrap<B>(errorMessage: String) -> EitherIO<Error, B> where A == B? {
    self.mapExcept(_requireSome(errorMessage))
  }
}

private func _requireSome<A>(
  _ message: String
) -> (Either<Error, A?>) -> Either<Error, A> {
  { e in
    switch e {
    case let .left(e):
      return .left(e)
    case let .right(a):
      return a.map(Either.right) ?? .left(RequireSomeError(message: message))
    }
  }
}

struct RequireSomeError: Error {
  let message: String
}
