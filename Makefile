BIN_PATH = $(shell swift build --show-bin-path)
XCTEST_PATH = $(shell find $(BIN_PATH) -name '*.xctest')
COV_BIN = $(XCTEST_PATH)/Contents/MacOs/$(shell basename $(XCTEST_PATH) .xctest)
COV_OUTPUT_PATH := "/tmp/swift-web-utils.lcov"

test-swift:
	@swift test --enable-code-coverage
  
test-linux:
	@docker run \
    --rm \
    --volume "$(PWD):$(PWD)" \
    --workdir "$(PWD)" \
    --platform linux/amd64 \
    swift:5.3 \
    bash Bootstrap/test.sh
    
test-all: test-swift test-linux

format:
	@docker run \
		--rm \
		--workdir "/work" \
		--volume "$(PWD):/work" \
		--platform linux/amd64 \
		mhoush/swift-format:latest \
		format \
		--in-place \
		--recursive \
		./Package.swift \
		./Sources/
		
check-for-llvm:
	test -f $(LLVM_PATH) || brew install llvm
	
code-cov: check-for-llvm
	rm -rf $(COV_OUTPUT_PATH)
	$(LLVM_PATH) export \
		$(COV_BIN) \
		-instr-profile=.build/debug/codecov/default.profdata \
		-ignore-filename-regex=".build|Tests" \
		-format lcov > $(COV_OUTPUT_PATH)
