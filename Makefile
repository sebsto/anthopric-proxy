AWS_PROFILE ?= default
TEST_BIN_NAME = anthropic-proxyPackageTests

build:
	container build -t anthropic-proxy -f ./Containerfile .

test:
	swift test

coverage:
	swift test --enable-code-coverage

# Find the test binary (macOS .xctest bundle vs Linux flat binary)
define find_test_bin
$$(BIN_DIR=$$(swift build --show-bin-path) && \
  if [ -f "$$BIN_DIR/$(TEST_BIN_NAME).xctest/Contents/MacOS/$(TEST_BIN_NAME)" ]; then \
    echo "$$BIN_DIR/$(TEST_BIN_NAME).xctest/Contents/MacOS/$(TEST_BIN_NAME)"; \
  else \
    echo "$$BIN_DIR/$(TEST_BIN_NAME)"; \
  fi)
endef

define find_profdata
$$(find .build -name 'default.profdata' -type f 2>/dev/null | head -1)
endef

coverage-report: coverage
	@BIN=$(find_test_bin) && \
	PROFILE=$(find_profdata) && \
	xcrun llvm-cov report "$$BIN" -instr-profile="$$PROFILE" \
		-ignore-filename-regex='\.build|Tests'

coverage-lcov: coverage
	@BIN=$(find_test_bin) && \
	PROFILE=$(find_profdata) && \
	xcrun llvm-cov export "$$BIN" -instr-profile="$$PROFILE" -format=lcov \
		-ignore-filename-regex='\.build|Tests' > coverage.lcov && \
	echo "Written to coverage.lcov"

run:
	@eval "$$(aws configure export-credentials --profile $(AWS_PROFILE) --format env)" && \
	container run --rm -it \
		-p 8080:8080 \
		-e PROXY_API_KEY \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_SESSION_TOKEN \
		-e AWS_REGION="$$(aws configure get region --profile $(AWS_PROFILE) 2>/dev/null || echo us-east-1)" \
		anthropic-proxy

.PHONY: build test coverage coverage-report coverage-lcov run
