import ApplicativeRouter
import CasePaths
import Foundation
import Prelude
import NonEmpty

// MARK: - Methods

extension Router {
  /// Create a router matching on a `DELETE` request.
  public static func delete() -> Router<Void> {
    method(.delete)
  }
  /// Create a router matching on a `GET` request.
  public static func get() -> Router<Void> {
    method(.get)
  }
  /// Create a router matching on a `HEAD` request.
  public static func head() -> Router<Void> {
    method(.head)
  }
  
  /// Create a router matching on an `OPTIONS` request.
  public static func options() -> Router<Void> {
    method(.options)
  }
  
  /// Create a router matching on a `PATCH` request.
  public static func patch() -> Router<Void> {
    method(.patch)
  }
  
  /// Create a router matching on a `POST` request.
  public static func post() -> Router<Void> {
    method(.post)
  }
  
  /// Create a router matching on a `PUT` request.
  public static func put() -> Router<Void> {
    method(.put)
  }
}

// MARK: - End
extension Router {
  /// Ends the router ensuring all path components have been consumed.
  ///
  /// In my testing if you experience errors where routes that use the same method are not getting matched,
  /// unless specified in a certain order when creating a router it's possibly because of not calling `end`.
  ///
  /// ## Example
  /// ```
  /// enum TestRouter {
  ///   case fetch
  ///   case fetch(id: Int)
  /// }
  ///
  /// let router1: Router<TestRouter> = .routes(
  ///   .get()
  ///     .path("test")
  ///     .case(/TestRouter.fetch),
  ///   .get()
  ///     .path("test")
  ///     .pathParam(.int)
  ///     .case(/TestRouter.fetch(id:))
  /// )
  ///  // router1 will not match on `GET` /test/42, but will match on `GET` /test
  ///
  /// let router2: Router<TestRouter> = .routes(
  ///   .get()
  ///     .path("test")
  ///     .pathParam(.int)
  ///     .case(/TestRouter.fetch(id:)),
  ///   .get()
  ///     .path("test")
  ///     .case(/TestRouter.fetch)
  /// )
  ///  // router2 would work as expeced and match on `GET` /test/42 and `GET` /test
  ///
  /// let router3: Router<TestRouter> = .routes(
  ///   .get()
  ///     .path("test")
  ///     .case(/TestRouter.fetch)
  ///     .end(),
  ///   .get()
  ///     .path("test")
  ///     .pathParam(.int)
  ///     .case(/TestRouter.fetch(id:))
  ///     .end()
  /// )
  ///  // router3 would work as expeced and match on `GET` /test/42 and `GET` /test
  ///  ```
  public func end() -> Router {
    self <% ApplicativeRouter.end
  }
}

// MARK: - Path
extension Router where A == Void {
  
  public func path(_ string: String) -> Router {
    self %> lit(sanitizePath(string))
  }
  
  public func path(_ components: NonEmptyArray<String>?) -> Router {
    guard let components = components else { return self }
    return self %> parsePath(components)
  }
  
  public func path(_ components: String...) -> Router {
    self.path(.init(rawValue: components))
  }
  
  public func pathParam<B>(_ param: PartialIso<String, B>) -> Router<B> {
    self %> ApplicativeRouter.pathParam(param)
  }
}

// MARK: - Case Paths
extension Router {
  
  public func `case`<B>(_ casePath: CasePath<B, A>) -> Router<B> {
    self.map(.case(casePath))
  }
}

// MARK: - Tuple

// TODO: Add more tuple types to allow for more than 2 parameters.
extension Router where A == Void {
  
  public func tuple<B, C>(_ lhs: Router<B>, _ rhs: Router<C>) -> Router<(B, C)> {
    self %> lhs <%> rhs
  }
}

extension Router {
  
  public func tuple<B>(_ rhs: Router<B>) -> Router<(A, B)> {
    self <%> rhs
  }
}

// MARK: - Query Param
extension Router where A == Void {
  
  public func queryParam<B>(_ key: String, _ param: PartialIso<String?, B>) -> Router<B> {
    self %> ApplicativeRouter.queryParam(key, param)
  }
}

// MARK: JSON Body
extension Router where A == Void {
  
  public func jsonBody<B>(
    _ type: B.Type,
    encoder: JSONEncoder = .init(),
    decoder: JSONDecoder = .init()
  ) -> Router<B> where B: Codable {
    self %> ApplicativeRouter.jsonBody(type, encoder: encoder, decoder: decoder)
  }
}

extension Router {
  public func jsonBody<B>(
    _ type: B.Type,
    encoder: JSONEncoder = .init(),
    decoder: JSONDecoder = .init()
  ) -> Router<(A, B)> where B: Codable {
    tuple(ApplicativeRouter.jsonBody(type, encoder: encoder, decoder: decoder))
  }
}

// MARK: Routes
extension Router {
  
  public static func routes(_ routes: Router...) -> Router {
    routes.reduce(.empty, <|>)
  }
}


// MARK: - Helpers

/// Strips any leading "/" from the path.
///
/// - Parameters:
///   - path: The path to sanitize.
private func sanitizePath(_ path: String) -> String {
  if path.starts(with: "/") {
    // call ourself recursively until all leading "/" are removed.
    return sanitizePath(String(path.dropFirst()))
  }
  return path
}

/// Sanitize and parse the path components used in routes.
///
/// - Parameters:
///   - first: The first path component to sanitize and parse.
///   - rest: The other path components to sanitize and parse.
private func parsePath(_ first: String, rest: ArraySlice<String>) -> Router<Void> {
  rest.reduce(lit(sanitizePath(first)), { $0 %> lit(sanitizePath($1)) })
}

/// Sanitize and parse the path components used in routes.
///
/// - Parameters:
///   - pathComponents: The path components to sanitize and parse.
private func parsePath(_ pathComponents: NonEmptyArray<String>) -> Router<Void> {
  return parsePath(pathComponents.first, rest: pathComponents.suffix(from: 1))
}
