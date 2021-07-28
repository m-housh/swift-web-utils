import XCTest
import CasePaths
import RouterUtils
import NonEmpty
import Prelude
import ApplicativeRouter

enum TestRoute: Equatable {
  case delete(id: Int)
  case fetchAll
  case fetchWithParam(RouteWithParam)
  case insert(InsertRequest)
  case update(id: Int, update: UpdateRequest)
  
  struct InsertRequest: Codable, Equatable {
    var name: String
  }
  
  struct UpdateRequest: Codable, Equatable {
    var name: String?
  }
}

enum RouteWithParam: Equatable {
  case fetch(foo: String?)
}

enum NestedRoute: Equatable {
  case deep1(Deep1)
  
  enum Deep1: Equatable {
    
    case deep2 (Deep2)
    
    enum Deep2: Equatable {
      case fetch
    }
  }
}

class RouterUtilsTestCase: XCTestCase {
  
  var router: Router<TestRoute>!
  var nestedRouter: Router<NestedRoute>!
  
  override func setUp() {
    super.setUp()
    
    let path: NonEmptyArray<String> = .init("/test")
    
    self.router = .chaining(
      .delete(/TestRoute.delete(id:), at: path) {
        pathParam(.int)
      },
      .get(/TestRoute.fetchAll, at: path),
      .post(/TestRoute.insert, at: path) {
        jsonBody(TestRoute.InsertRequest.self)
      },
      .post(/TestRoute.update(id:update:), at: path) {
        pathParam(.int) {
          jsonBody(TestRoute.UpdateRequest.self)
        }
      },
      .get(/TestRoute.fetchWithParam, at: .init("test", "param")) {
        .case(/RouteWithParam.fetch(foo:)) {
          queryParam("foo", opt(.string))
        }
      }
    )
    
    self.nestedRouter = .case(/NestedRoute.deep1, at: .init("deep1")) {
      .case(/NestedRoute.Deep1.deep2, at: .init("deep2")) {
        .get(/NestedRoute.Deep1.Deep2.fetch, at: .init("deep3"))
      }
    }
    
    self.router = .routes(
      .delete()
        .path("test")
        .pathParam(.int)
        .case(/TestRoute.delete(id:))
        .end(),
      .get()
        .path("test")
        .case(/TestRoute.fetchAll)
        .end(),
      .get()
        .path("test", "param")
        .queryParam("foo", opt(.string))
        .case(/RouteWithParam.fetch(foo:))
        .case(/TestRoute.fetchWithParam)
        .end(),
      .post()
        .path("test")
        .jsonBody(TestRoute.InsertRequest.self)
        .case(/TestRoute.insert)
        .end(),
      .post()
        .path("test")
        .tuple(pathParam(.int), jsonBody(TestRoute.UpdateRequest.self))
        .case(/TestRoute.update(id:update:))
        .end()
        
    )
  }
}
