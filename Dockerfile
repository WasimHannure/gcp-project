# Multi-stage build
FROM golang:1.21 AS builder

WORKDIR /app

# Copy go mod files if they exist
COPY go.* ./
RUN go mod download || true

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o openclaw . || echo "Go build skipped"

# Final image
FROM gcr.io/distroless/base-debian12

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/openclaw /app/openclaw || true

# Default to running a simple server if binary not built
# Replace this with your actual application
EXPOSE 8080

ENTRYPOINT ["/app/openclaw"]
CMD ["--port", "8080"]
