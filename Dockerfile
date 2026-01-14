FROM golang:1.25-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

COPY much-to-do/Server/MuchToDo/go.mod much-to-do/Server/MuchToDo/go.sum ./

RUN go mod download

COPY much-to-do/Server/MuchToDo/ .

RUN CGO_ENABLED=0 GOOS=linux go build -o muchtodo ./cmd/api 

#------------stage2:production-----

FROM alpine:3.19

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# install wiget for health checks
RUN apk --no-cache add wget

COPY --from=builder /app/muchtodo . 


EXPOSE 3000

#add a non-root user 
USER appuser
#health check
HEALTHCHECK --interval=30s --timeout=3s \ 
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start the application
CMD ["./muchtodo"]
