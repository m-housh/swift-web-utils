import XCTest
import DatabaseUtils
import Either
import NIO
import SQLiteKit
import Prelude

struct TestDataModel: Codable, Identifiable, Equatable {
  var id: Int
  var description: String
}

struct TestDatabaseClient {

  var delete: (Int) -> EitherIO<Error, Void>
  var fetchAll: () -> EitherIO<Error, [TestDataModel]>
  var fetchId: (Int) -> EitherIO<Error, TestDataModel>
  var insert: (InsertRequest) -> EitherIO<Error, TestDataModel>
  var migrate: () -> EitherIO<Error, Void>
  var update: (TestDataModel) -> EitherIO<Error, TestDataModel>
  
  struct InsertRequest: Equatable, Codable {
    let description: String
  }
}

private let table = SQLIdentifier("test")
struct TestError: Error { }

extension TestDatabaseClient {

  static func testing(on connection: SQLiteConnection) -> Self {
    .init(
      delete: DatabaseCrud.delete(from: table, on: connection.sql()),
      fetchAll: DatabaseCrud.fetch(from: table, on: connection.sql()),
      fetchId: DatabaseCrud.fetchId(from: table, on: connection.sql()),
      insert: { request in
        // SQLiteKit does not return values when inserting, so we have to fetch after inserting ??
        .catching {
          try insertBuilder(inserting: request, to: table, on: connection.sql())
            .run()
            .flatMap {
              fetchBuilder(from: table, on: connection.sql())
                .where("description", .equal, request.description)
                .first(decoding: TestDataModel.self)
                .mapExcept({ e in
                  switch e {
                  case let .left(error):
                    return .left(error)
                  case let .right(optionalData):
                    return optionalData.map(Either.right) ?? .left(TestError())
                  }
                })
            }
          }
      },
      migrate: {
        sequence([
          connection.sql().run("""
            CREATE TABLE IF NOT EXISTS "test"(
              "id" integer primary key autoincrement,
              "description" text not null
            )
            """)
        ])
        .map(const(()))
      },
      update: { request in
        .catching {
            try updateBuilder(updating: request, table: table, on: connection.sql())
              .run()
              .flatMap {
                fetchIdBuilder(id: request.id, from: table, on: connection.sql())
                  .first(decoding: TestDataModel.self)
                  .mapExcept({ e in
                    switch e {
                    case let .left(error):
                      return .left(error)
                    case let .right(optionalData):
                      return optionalData.map(Either.right) ?? .left(TestError())
                    }
                  })
              }
          }
          
      }
    )
  }
  
  func resetForTesting(on connection: SQLiteConnection) throws {
    try connection.sql().run("DROP TABLE IF EXISTS test").run.perform().unwrap()
    try self.migrate().run.perform().unwrap()
  }
}

class DatabaseUtilsTestCase: XCTestCase {
  
  var eventLoopGroup: EventLoopGroup!
  var threadPool: NIOThreadPool!
  var connection: SQLiteConnection!
  var client: TestDatabaseClient!
  
  override func setUp() {
    super.setUp()
    self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    self.threadPool = NIOThreadPool(numberOfThreads: 1)
    self.threadPool.start()
    self.connection = try! SQLiteConnectionSource(
      configuration: .init(storage: .memory),
      threadPool: self.threadPool
    )
    .makeConnection(
      logger: .init(label: "test"),
      on: self.eventLoopGroup.next()
    )
    .wait()
    
    self.client = .testing(on: self.connection)
    
    try! self.client.resetForTesting(on: self.connection)
  }
  
  override func tearDown() {
    super.tearDown()
    try! self.connection.close().wait()
    self.connection = nil
    try! self.threadPool.syncShutdownGracefully()
    self.threadPool = nil
    try! self.eventLoopGroup.syncShutdownGracefully()
    self.eventLoopGroup = nil
  }
}
