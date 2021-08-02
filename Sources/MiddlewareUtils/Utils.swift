import Either
import Foundation
import HttpPipeline
import Prelude

/// Sends / encodes json data as the response type from incoming requests, finalizing the response.
public func respondJson<A: Encodable>(
  testing: Bool = false
) -> (Conn<StatusLineOpen, A>) -> IO<Conn<ResponseEnded, Data>> {
  { conn in
    let encoder = JSONEncoder()
    if testing {
      encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    }

    guard let data = try? encoder.encode(conn.data) else {
      let data = "Badly formed json".data(using: .utf8)!
      return conn.map(const(data))
        |> writeStatus(.badRequest)
        >=> writeHeader(.contentLength(data.count))
        >=> closeHeaders
        >=> end
    }

    return conn.map(const(data))
      |> writeStatus(.ok)
      >=> writeHeader(.contentType(.json))
      >=> writeHeader(.contentLength(data.count))
      >=> closeHeaders
      >=> end
  }
}

public func respondJson<A: Encodable>(
  testing: Bool = false
) -> (Conn<HeadersOpen, A>) -> IO<Conn<ResponseEnded, Data>> {
  { conn in
    let encoder = JSONEncoder()
    if testing {
      encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    }

    guard let data = try? encoder.encode(conn.data) else {
      let data = "Badly formed json".data(using: .utf8)!
      return conn.map(const(data))
        |> writeHeader(.contentLength(data.count))
        >=> closeHeaders
        >=> end
    }

    return conn.map(const(data))
      |> writeHeader(.contentType(.json))
      >=> writeHeader(.contentLength(data.count))
      >=> closeHeaders
      >=> end
  }
}

extension EitherIO where E == Error, A: Encodable {

  public func respondJson<B>(
    on connection: Conn<StatusLineOpen, B>,
    testing: Bool = false
  ) -> IO<Conn<ResponseEnded, Data>> {
    self.run.flatMap { eitherErrorOrValue in
      switch eitherErrorOrValue {
      case let .left(error):
        return connection.map(const(ApiError(error: error)))
          |> writeStatus(.internalServerError)
          >=> MiddlewareUtils.respondJson(testing: testing)
      case let .right(value):
        return connection.map(const(value))
          |> MiddlewareUtils.respondJson(testing: testing)
      }
    }
  }
}

extension EitherIO where E == Error, A == Void {

  public func respondJson<B>(
    on connection: Conn<StatusLineOpen, B>,
    testing: Bool = false
  ) -> IO<Conn<ResponseEnded, Data>> {
    self.run.flatMap { eitherErrorOrValue in
      switch eitherErrorOrValue {
      case let .left(error):
        return connection.map(const(ApiError(error: error)))
          |> writeStatus(.internalServerError)
          >=> MiddlewareUtils.respondJson(testing: testing)
      case .right:
        return connection.map(const(EmptyCodable()))
          |> MiddlewareUtils.respondJson(testing: testing)
      }
    }
  }
}

/// Represents errors that are thrown from the api. By wrapping an error that was thrown
/// and allowing it to be codable to be sent for debugging.
struct ApiError: Codable, Error, Equatable, LocalizedError {

  /// The wrapped error dump.
  public let errorDump: String

  /// The file it was thrown from.
  public let file: String

  /// The line it was thrown from.
  public let line: UInt

  /// The error message.
  public let message: String

  /// Create a new api error.
  ///
  /// - Parameters:
  ///  - error: The error that was thrown / we are wrapping.
  ///  - file: The file it was thrown from.
  ///  - line: The line it was thrown from.
  public init(
    error: Error,
    file: StaticString = #fileID,
    line: UInt = #line
  ) {
    var string = ""
    dump(error, to: &string)
    self.errorDump = string
    self.file = String(describing: file)
    self.line = line
    self.message = error.localizedDescription
  }

  public var errorDescription: String? {
    self.message
  }
}

struct EmptyCodable: Codable {}
