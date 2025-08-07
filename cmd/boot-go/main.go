// File: cmd/boot-go/main.go
package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	"google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/reflection"

	// Use the local module path.
	pb "boot-go/internal/grpc/generated"
	"boot-go/pkg/server"
)

// main is the entry point for the boot-go plugin.
func main() {
	log.SetOutput(os.Stderr)

	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		log.Fatalf("Failed to listen on a port: %v", err)
	}

	// Create a new gRPC server instance.
	s := grpc.NewServer()

	// Create the plugin server
	pluginServer, err := server.New()
	if err != nil {
		log.Fatalf("Failed to create plugin server: %v", err)
	}

	// Register the plugin service
	pb.RegisterBootCodePluginServer(s, pluginServer)
	
	// Add health check service for better gRPC client compatibility
	healthServer := health.NewServer()
	grpc_health_v1.RegisterHealthServer(s, healthServer)
	healthServer.SetServingStatus("", grpc_health_v1.HealthCheckResponse_SERVING)
	
	// Register reflection for debugging
	reflection.Register(s)

	// --- The Handshake ---
	// Output the handshake AFTER the server is fully configured
	fmt.Printf("1|1|tcp|%s|grpc\n", listener.Addr().String())
	
	// Flush stdout to ensure the handshake is sent immediately
	os.Stdout.Sync()

	// --- Graceful Shutdown Setup ---
	// Create a channel to receive OS signals.
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// --- Run Server in a Goroutine ---
	serverErrChan := make(chan error, 1)
	go func() {
		log.Printf("Plugin gRPC server starting on %s", listener.Addr())
		if err := s.Serve(listener); err != nil {
			serverErrChan <- err
		}
	}()

	// Give the server a moment to fully start
	time.Sleep(100 * time.Millisecond)

	// --- Block until a signal is received or server fails ---
	select {
	case <-sigChan:
		log.Println("Shutdown signal received, stopping gRPC server...")
	case err := <-serverErrChan:
		log.Printf("gRPC server failed: %v", err)
		os.Exit(1)
	}

	// --- Shutdown ---
	s.GracefulStop()
	log.Println("gRPC server stopped.")
}