import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import MiddlewareUtils
import RouterUtils
import Prelude

struct TestModel: Codable, Equatable, Identifiable {
  var id: Int
  var name: String
}

enum TestRoute {
  case delete(id: Int)
  case fetchAll
}

let testRouter = Router<TestRoute>.routes(
  Router<TestRoute>.get()
    .path("test")
    .case(/TestRoute.fetchAll)
    .end(),
  Router<TestRoute>.delete()
    .path("test")
    .pathParam(.int)
    .case(/TestRoute.delete(id:))
    .end()
)

extension EitherIO {
  
  init(value: A) {
    self.init(run: .init { .right(value) })
  }
}

struct TestDatabase {
  var delete: (Int) -> EitherIO<Error, Void>
  var fetchAll: () -> EitherIO<Error, [TestModel]>
  
  init() {
    self.delete = { _ in .init(value: ()) }
    self.fetchAll = {
      .init(value: [.init(id: 1, name: "blob"), .init(id: 2, name: "blob-jr"), .init(id: 3, name: "blob-sr")])
    }
  }
}

let _testMiddleware: Middleware<StatusLineOpen, ResponseEnded, TestRoute, Data> = { conn in
  let database = TestDatabase()
  let route = conn.data

  switch route {
  case let .delete(id):
    return database.delete(id)
      .respondJson(on: conn, testing: true)

  case .fetchAll:
    return database.fetchAll()
      .respondJson(on: conn, testing: true)
  }
}

let testMiddleware: Middleware<StatusLineOpen, ResponseEnded, Prelude.Unit, Data> = route(
  router: testRouter
) <| _testMiddleware
