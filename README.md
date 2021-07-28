[![CI](https://github.com/m-housh/swift-web-utils/actions/workflows/ci.yml/badge.svg)](https://github.com/m-housh/swift-web-utils/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/m-housh/swift-web-utils/branch/main/graph/badge.svg?token=kdnbd2tgij)](https://codecov.io/gh/m-housh/swift-web-utils)
[![documentation](https://img.shields.io/badge/Api-Documentation-orange)](https://github.com/m-housh/swift-web-utils/wiki)

# swift-web-utils

Extends the [pointfreeco/swift-web](https://github.com/pointfreeco/swift-web) package.  Adds a more convenient
syntax for creating routers.  This was inspired / created after exploring their framework in my
[swift-web-playground](https://github.com/m-housh/swift-web-playground) package, where I created a simple
CRUD server.

It should be noted that `pointfreeco` will likely build wrappers around their framework that may make
this package obsolete in the future, but this can possibly act as a stop gap until then.  This package
also aims to deliver better syntax for small / not too complicated of routes and may breakdown in more
complex scenarios.

# Quickstart Guide

This a swift package, so to use in your project then include it in your project's `Package.swift` file
or using `Xcode`.

```swift
let package = Package(
  name: "swift-web-utils",
  platforms: [
    .macOS(.v10_13)
  ],
  products: [...],
  dependencies: [
    .package(url: "https://github.com/m-housh/swift-web-utils", from: "0.1.0"),
    ...
  ],
  targets: [...]
)
```

### Build a router.

Routes are modeled as enum cases.  Below would be how to create router with CRUD routes.

**Routes.swift**
```swift
import Foundation

enum UserRoute: Equatable {
  
  case fetchAll
  case fetch(id: User.ID)
  case insert(InsertRequest)
  case update(id: User.ID, updates: UpdateRequest)
  case delete(id: User.ID)
  
  struct InsertRequest: Codable, Equatable {
    let name: String
    
    init(name: String) {
      self.name = name
    }
  }
  
  struct UpdateRequest: Codable, Equatable {
    let name: String?
    
    init(name: String?) {
      self.name = name
    }
  }
}

struct User: Codable, Equatable, Identifiable {
    
  var id: UUID
  var name: String
    
  init(id: UUID, name: String) {
    self.id = id
    self.name = name
  }
}
```

Next create the router that handles incoming request connections and parses them into `UserRoutes`.

**Router.swift**
```swift
import ApplicativeRouter
import CasePaths
import RouterUtils

let userRouter: Router<UserRoute> = .routes(
  .get()
    .path("users")
    .case(/UserRoute.fetchAll)
    .end(),
    
  .get()
    .path("users")
    .pathParam(.uuid)
    .case(/UserRoute.fetch(id:))
    .end(),
    
  .post()
    .path("users")
    .jsonBody(UserRoute.InsertRequest.self)
    .case(/UserRoute.insert)
    .end(),
  
  .patch()
    .path("users")
    .tuple(pathParam(.uuid), jsonBody(UserRoute.UpdateRequest.self))
    .case(/UserRoute.update(id:updates:))
    .end(),
    
  .delete()
    .path("users")
    .pathParam(.uuid)
    .case(/UserRoute.delete(id:))
    .end()
)
```

Creating the router middleware is beyond the scope of this document, but you can check out some of the
[pointfreeco](https://github.com/pointfreeco) projects or my 
[swift-web-playground](https://github.com/m-housh/swift-web-playground) for a complete server implementation.
