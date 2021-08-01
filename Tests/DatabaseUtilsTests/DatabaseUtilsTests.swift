import XCTest

@testable import DatabaseUtils

class DatabaseUtilsTests: DatabaseUtilsTestCase {
  
  func testCrud() throws {
    
    let insertRequest = TestDatabaseClient.InsertRequest(description: "blob")
    let inserted = try self.client.insert(insertRequest).run.perform().unwrap()

    XCTAssertEqual(inserted.id, 1)
    XCTAssertEqual(inserted.description, "blob")
    
    let fetched = try self.client.fetchAll().run.perform().unwrap()
    XCTAssertEqual(fetched.count, 1)
    XCTAssertEqual(fetched.first!, inserted)
    
    let fetchedId = try self.client.fetchId(1).run.perform().unwrap()
    XCTAssertEqual(fetchedId, inserted)
    
    let update = TestDataModel(id: 1, description: "updated-blob")
    let updated = try self.client.update(update).run.perform().unwrap()
    XCTAssertEqual(updated.id, 1)
    XCTAssertEqual(updated.description, "updated-blob")
    
    let fetched2 = try self.client.fetchAll().run.perform().unwrap()
    XCTAssertEqual(fetched2.count, 1)
    
    try self.client.delete(1).run.perform().unwrap()
    let fetched3 = try self.client.fetchAll().run.perform().unwrap()
    XCTAssertEqual(fetched3.count, 0)
  }
}
