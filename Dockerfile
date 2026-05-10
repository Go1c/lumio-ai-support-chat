FROM golang:1.22-alpine AS build

WORKDIR /src
COPY go.mod ./
COPY *.go ./
RUN go test ./...
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/lumio-ai-support-chat .

FROM alpine:3.20

RUN adduser -D -H app
USER app
WORKDIR /app
COPY --from=build /out/lumio-ai-support-chat /app/lumio-ai-support-chat

EXPOSE 8080
CMD ["/app/lumio-ai-support-chat"]
