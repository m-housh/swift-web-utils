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
      delete: { id in
        connection.sql().delete(from: table)
          .where("id", .equal, id)
          .run()
      },
      fetchAll: {
        connection.sql().select()
          .column(.all)
          .from(table)
          .all(decoding: TestDataModel.self)
      },
      fetchId: { id in
        connection.sql().select()
          .column(.all)
          .from(table)
          .where("id", .equal, id)
          .first(decoding: TestDataModel.self)
          .unwrap(errorMessage: "fetchId: \(id)")
      },
      insert: { request in
        // SQLiteKit does not return values when inserting, so we have to fetch after inserting ??
        .catching {
          try connection.sql().insert(into: table)
            .model(request)
            .run()
            .flatMap {
              connection.sql().select()
                .column(.all)
                .from(table)
                .where("description", .equal, request.description)
                .first(decoding: TestDataModel.self)
                .unwrap(errorMessage: "insert: \(request)")
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
          try connection.sql().update(table)
              .set(model: request)
              .run()
              .flatMap {
                connection.sql().select()
                  .column(.all)
                  .from(table)
                  .where("id", .equal, request.id)
                  .first(decoding: TestDataModel.self)
                  .unwrap(errorMessage: "update: \(request)")
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
