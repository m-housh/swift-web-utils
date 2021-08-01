#!/bin/sh
apt-get --fix-missing update
apt-get install -y \
  libssl-dev openssl sqlite3 libsqlite3-dev
swift test --enable-test-discovery || exit $?
