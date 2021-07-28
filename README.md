[![CI](https://github.com/m-housh/swift-web-utils/actions/workflows/ci.yml/badge.svg)](https://github.com/m-housh/swift-web-utils/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/m-housh/swift-web-utils/branch/main/graph/badge.svg?token=kdnbd2tgij)](https://codecov.io/gh/m-housh/swift-web-utils)

# swift-web-utils

Extends the [pointfreeco/swift-web](https://github.com/pointfreeco/swift-web) package.  Adds a more convenient
syntax for creating routers.  This was inspired / created after exploring their framework in my
[swift-web-playground](https://github.com/m-housh/swift-web-playground) package, where I created a simple
CRUD server.

It should be noted that `pointfreeco` will likely build wrappers around their framework that may make
this package obsolete in the future, but this can possibly act as a stop gap until then.  This package
also aims to deliver better syntax for small / not too complicated of routes and may breakdown in more
complex scenarios.
