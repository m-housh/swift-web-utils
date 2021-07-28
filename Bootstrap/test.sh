#!/bin/sh
apt-get --fix-missing update
apt-get install -y \
  libssl-dev openssl
swift test --enable-test-discovery || exit $?
