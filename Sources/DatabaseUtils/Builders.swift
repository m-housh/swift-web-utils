import Foundation
import NonEmpty
import SQLKit

/// Creates an `SQLDeleteBuilder` that can be extended or executed later.
///
/// - Parameters:
///    - id: The id of the model to delete from the database.
///    - table: The table identifier to delete the model from.
///    - database: The database to run the request on.
///    - idColumn: The id column identifier, defaults to "id".
public func deleteBuilder<ID>(
  id: ID,
  from table: SQLExpression,
  on database: SQLDatabase,
  idColumn: SQLExpression = SQLIdentifier("id")
) -> SQLDeleteBuilder
where ID: Encodable {
  database.delete(from: table)
    .where(idColumn, .equal, SQLBind(id))
}

/// Creates an `SQLSelectBuilder` that can be extended or executed later.
///
/// Typically used to fetch all / a list of models from the database.
///
/// - Parameters:
///    - table: The table identifier to fetch the model from.
///    - database: The database to run the request on.
///    - columns: The columns to return from the table, defaults all columns.
public func fetchBuilder(
  from table: SQLExpression,
  on database: SQLDatabase,
  returning columns: NonEmptyArray<String> = .init(.all)
) -> SQLSelectBuilder {
  database.select()
    .columns(columns.rawValue)
    .from(table)
}

/// Creates an `SQLSelectBuilder` that can be extended or executed later.
///
/// Used to fetch a specific model by id.
///
/// - Parameters:
///    - id: The id of the model to delete from the database.
///    - table: The table identifier to fetch the model from.
///    - database: The database to run the request on.
///    - idColumn: The id column identifier, defaults to "id".
///    - columns: The columns to return from the table, defaults all columns.
public func fetchIdBuilder<ID>(
  id: ID,
  from table: SQLExpression,
  on database: SQLDatabase,
  idColumn: SQLExpression = SQLIdentifier("id"),
  returning columns: NonEmptyArray<String> = .init(.all)
) -> SQLSelectBuilder
where ID: Encodable {
  fetchBuilder(from: table, on: database, returning: columns)
    .where(idColumn, .equal, SQLBind(id))
}

/// Creates an `SQLInsertBuilder` that can be extended or executed later.
///
/// Used to insert a new model.
///
/// - Parameters:
///    - model: The model to insert in the database.
///    - table: The table identifier to insert the model.
///    - database: The database to run the request on.
///    - idColumn: The id column identifier, defaults to "id".
public func insertBuilder<Insert>(
  inserting model: Insert,
  to table: SQLExpression,
  on database: SQLDatabase
) throws -> SQLInsertBuilder
where Insert: Encodable {
  try database.insert(into: table)
    .model(model)
}

/// Creates an `SQLSelectBuilder` that can be extended or executed later.
///
/// Used to fetch a specific model by id.
///
/// - Parameters:
///    - id: The id of the model to update in the database.
///    - table: The table identifier to update the model on.
///    - database: The database to run the request on.
///    - idColumn: The id column identifier, defaults to "id".
public func updateBuilder<Update>(
  updating model: Update,
  table: SQLExpression,
  on database: SQLDatabase,
  idColumn: SQLExpression = SQLIdentifier("id")
) throws -> SQLUpdateBuilder
where Update: Encodable, Update: Identifiable, Update.ID: Encodable {
  try database.update(table)
    .where(idColumn, .equal, SQLBind(model.id))
    .set(model: model)
}
