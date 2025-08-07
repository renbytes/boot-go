.PHONY: all build run test clean tidy install proto

# Variables
APP_NAME := boot-go
CMD_PACKAGE := ./cmd/$(APP_NAME)
OUTPUT_DIR := ./bin
BINARY_PATH := $(OUTPUT_DIR)/$(APP_NAME)

# Default target
all: build

# Build the application from the project root.
build:
	@echo "Building $(APP_NAME)..."
	@mkdir -p $(OUTPUT_DIR)
	@go build -o $(BINARY_PATH) $(CMD_PACKAGE)

# Run the application
run:
	@go run $(CMD_PACKAGE)

# Test the application
test:
	@echo "Running tests..."
	@go test -v ./...

# Tidy dependencies
tidy:
	@echo "Tidying go.mod..."
	@go mod tidy

# Generate gRPC code from proto file
proto:
	@echo "Generating gRPC code..."
	@protoc --go_out=. --go_opt=paths=source_relative \
		--go-grpc_out=. --go-grpc_opt=paths=source_relative \
		proto/plugin.proto

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -f $(BINARY_PATH)

# Install the binary to a standard system-wide location.
install: build
	@echo "Installing $(APP_NAME) to /usr/local/bin..."
	@cp $(BINARY_PATH) /usr/local/bin/$(APP_NAME)
	@echo "$(APP_NAME) installed successfully."