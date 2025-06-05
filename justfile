# Default features
features := env_var_or_default("FEATURES", "")

# Git version info
git_ver := `git describe --tags --always --dirty="-dev"`
git_tag := `git describe --tags --abbrev=0`

# Show the current version
v:
  @echo "Version: {{git_ver}}"

##@ Help

# Display help information
help:
  @just --list

##@ Build

# Clean up build artifacts
clean:
  cargo clean

# Build (debug version)
build:
  cargo build --features "{{features}}"

# Build op-rbuilder (debug version)
op-rbuilder:
  cargo build -p op-rbuilder --bin op-rbuilder --features "{{features}}"

# Build tester (debug version)
tester:
  cargo build -p op-rbuilder --bin tester --features "testing,{{features}}"

# Build a rbuilder Docker image
docker-image-rbuilder:
  docker build --platform linux/amd64 --target rbuilder-runtime --build-arg FEATURES="{{features}}" . -t rbuilder

##@ Dev

# Run the linters
lint:
  cargo +nightly fmt -- --check
  cargo +nightly clippy --features "{{features}}" -- -D warnings
  cargo +nightly clippy -p op-rbuilder --features "{{features}}" -- -D warnings

# Run the tests for rbuilder and op-rbuilder
test:
  cargo test --verbose --features "{{features}}"
  cargo test -p op-rbuilder --verbose --features "{{features}}"

# Run "lint" and "test"
lt: lint test

# Format the code
fmt:
  cargo +nightly fmt
  cargo +nightly fix --allow-staged
  cargo +nightly clippy --features "{{features}}" --fix --allow-staged
  cargo +nightly clippy -p op-rbuilder --features "{{features}}" --fix --allow-staged

# Run benchmarks
bench:
  cargo bench --features "{{features}}" --workspace

# Open last benchmark report in the browser
bench-report-open:
  open "target/criterion/report/index.html"

# Run benchmarks in CI (adds timestamp and version to the report, customizes Criterion output)
bench-in-ci:
  ./scripts/ci/benchmark-in-ci.sh

# Remove previous benchmark data
bench-clean:
  rm -rf target/criterion
  rm -rf target/benchmark-in-ci
  rm -rf target/benchmark-html-dev

# Prettifies the latest Criterion report
bench-prettify:
  rm -rf target/benchmark-html-dev
  ./scripts/ci/criterion-prettify-report.sh target/criterion target/benchmark-html-dev
  @echo "\nopen target/benchmark-html-dev/report/index.html"

##@ Original justfile commands

# Build and run op-rbuilder in playground mode for testing
run-playground:
  cargo build --bin op-rbuilder -p op-rbuilder
  ./target/debug/op-rbuilder node --builder.playground

# Run the complete test suite (genesis generation, build, and tests)
run-tests:
  just generate-test-genesis
  just build-op-rbuilder
  just run-tests-op-rbuilder

# Download `op-reth` binary
download-op-reth:
  ./scripts/ci/download-op-reth.sh

# Generate a genesis file (for tests)
generate-test-genesis:
  cargo run -p op-rbuilder --features="testing" --bin tester -- genesis --output genesis.json

# Build the op-rbuilder binary
build-op-rbuilder:
  cargo build -p op-rbuilder --bin op-rbuilder

# Run the integration tests
run-tests-op-rbuilder:
  PATH=$PATH:$(pwd) cargo test --package op-rbuilder --lib
