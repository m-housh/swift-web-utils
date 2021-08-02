import XCTest
import HttpPipeline
import HttpPipelineTestSupport
import SnapshotTesting
@testable import MiddlewareUtils

class MiddlewareUtilsTests: XCTestCase {
  
  func testRespondJsonOnVoidValues() {
    var request = URLRequest(url: URL(string: "/test/1")!)
    request.httpMethod = "delete"
    let response = testMiddleware(connection(from: request)).perform()
    
    _assertInlineSnapshot(matching: response, as: .conn, with: #"""
    DELETE /test/1

    200 OK
    Content-Length: 4
    Content-Type: application/json
    Referrer-Policy: strict-origin-when-cross-origin
    X-Content-Type-Options: nosniff
    X-Download-Options: noopen
    X-Frame-Options: SAMEORIGIN
    X-Permitted-Cross-Domain-Policies: none
    X-XSS-Protection: 1; mode=block

    "{}"
    """#)
  }
  
  func testRespondJsonOnEncodableValues() {
    var request = URLRequest(url: URL(string: "/test")!)
    request.httpMethod = "get"
    let response = testMiddleware(connection(from: request)).perform()
    
    _assertInlineSnapshot(matching: response, as: .conn, with: #"""
    GET /test

    200 OK
    Content-Length: 137
    Content-Type: application/json
    Referrer-Policy: strict-origin-when-cross-origin
    X-Content-Type-Options: nosniff
    X-Download-Options: noopen
    X-Frame-Options: SAMEORIGIN
    X-Permitted-Cross-Domain-Policies: none
    X-XSS-Protection: 1; mode=block

    [
      {
        "id" : 1,
        "name" : "blob"
      },
      {
        "id" : 2,
        "name" : "blob-jr"
      },
      {
        "id" : 3,
        "name" : "blob-sr"
      }
    ]
    """#)
  }
}
