import Either
import Foundation
import SQLKit

/// A namespace for creating common database crud operations, used in database clients.
public enum DatabaseCrud {

  /// Creates a function that can be used to delete a model by id from the database.
  ///
  /// - Parameters:
  ///    - table: The table identifier to delete the model from.
  ///    - database: The database to run the request on.
  ///    - idColumn: The id column identifier, defaults to "id".
  public static func delete<ID>(
    from table: SQLExpression,
    on database: SQLDatabase,
    idColumn: SQLExpression = SQLIdentifier("id")
  ) -> (ID) -> EitherIO<Error, Void>
  where ID: Encodable {
    { id -> EitherIO<Error, Void> in
      deleteBuilder(id: id, from: table, on: database).run()
    }
  }

  /// Creates a function that can be used to fetch all models from the database.
  ///
  /// - Parameters:
  ///    - table: The table identifier to delete the model from.
  ///    - pool: The connection pool to run the request on.
  public static func fetch<Model>(
    from table: SQLExpression,
    on database: SQLDatabase
  ) -> () -> EitherIO<Error, [Model]>
  where Model: Decodable {
    {
      fetchBuilder(from: table, on: database)
        .all(decoding: Model.self)
    }
  }

  /// Creates a function that can be used to fetch a model by id from the database.
  ///
  /// - Parameters:
  ///    - table: The table identifier to delete the model from.
  ///    - pool: The connection pool to run the request on.
  ///    - idColumn: The id column identifier, defaults to "id".
  public static func fetchId<ID, Model>(
    from table: SQLExpression,
    on database: SQLDatabase,
    idColumn: SQLExpression = SQLIdentifier("id")
  ) -> (ID) -> EitherIO<Error, Model>
  where ID: Encodable, Model: Decodable {
    { id -> EitherIO<Error, Model> in
      fetchIdBuilder(id: id, from: table, on: database)
        .first(decoding: Model.self)
        .mapExcept(requireSome("fetchId: \(table) : \(id)"))
    }
  }

  /// Creates a function that can be used to insert a model into the database.
  ///
  /// - Parameters:
  ///    - table: The table identifier to delete the model from.
  ///    - pool: The connection pool to run the request on.
  public static func insert<Insert, Model>(
    to table: SQLExpression,
    on database: SQLDatabase
  ) -> (Insert) -> EitherIO<Error, Model>
  where Insert: Encodable, Model: Decodable {
    { request in
      .catching {
        try insertBuilder(inserting: request, to: table, on: database)
          .returning(.all)
          .first(decoding: Model.self)
          .mapExcept(requireSome("insert: \(table) : \(request)"))
      }
    }
  }

  /// Creates a function that can be used to update a model by id in the database.
  ///
  /// - Parameters:
  ///    - table: The table identifier to delete the model from.
  ///    - pool: The connection pool to run the request on.
  ///    - idColumn: The id column identifier, defaults to "id".
  public static func update<Update, Model>(
    table: SQLExpression,
    on database: SQLDatabase,
    idColumn: SQLExpression = SQLIdentifier("id")
  ) -> (Update) -> EitherIO<Error, Model>
  where Update: Encodable, Update: Identifiable, Update.ID: Encodable, Model: Decodable {
    { request in
      .catching {
        try updateBuilder(updating: request, table: table, on: database, idColumn: idColumn)
          .returning(.all)
          .first(decoding: Model.self)
          .mapExcept(requireSome("update: \(table) : \(request)"))
      }
    }
  }
}

private func requireSome<A>(
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
