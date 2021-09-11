---
layout: post
title: "Microservice example application with Docker Swarm, Golang, gRPC, GraphQL, TypeScript and React - Part I"
date: 2021-09-08 19:30:00 +0300
tags: docker golang grpc typescript react microservices
---

> This post will cover creation of folder structure, gateway and auth services' scaffold.

## What is it?

Hello, in this blog post I will create an example microservices structure using a graphql gateway API and a client written in TypeScript and React.

Before start coding, let us look into drawing for basic structure:

![example project structure]({{site.baseurl}}/assets/img/2021_09_09_microservices/structure.png)

This project will simply login users with mock authentication data and allow them to add products to carts and create orders. I won't be using and kind of data storage for now because of I want to keep it simple.

## Project components

# Auth service

This service will handle login requests and respond with generated mock login info like first name, avatar.

# Product service

This service will serve product list.

# Cart service

This service will handle:

+ add to cart,
+ remove from cart,
+ flush cart (when order is completed)

# Order service

This service will handle order creations.

# API Gateway

This will be façade of our project. Our React application will talk with this gateway via GraphQL.

# React Application

This will handle all of operations and serve us graphical interface for our project.


Let us commence!

## Creating gateway service

I will name this project "fake_store". You can find it on [GitHub](https://github.com/yigitsadic/fake_store)

First create folder with

```
mkdir fake_store
```

Initialize Go module and touch docker-compose file.

```
go mod init github.com/yigitsadic/fake_store

touch docker-compose.yml
```

I want to start with GraphQL API Gateway

```
mkdir gateway && cd gateway
```

I will use [github.com/99designs/gqlgen](https://github.com/99designs/gqlgen) for handling GraphQL server in Go.

```
go get github.com/99designs/gqlgen
go run github.com/99designs/gqlgen init .
```

This will generate some boilerplate for our project. I took it from it's docs.

```
├── gqlgen.yml               - The gqlgen config file, knobs for controlling the generated code.
├── graph
│   ├── generated            - A package that only contains the generated runtime
│   │   └── generated.go
│   ├── model                - A package for all your graph models, generated or otherwise
│   │   └── models_gen.go
│   ├── resolver.go          - The root graph resolver type. This file wont get regenerated
│   ├── schema.graphqls      - Some schema. You can split the schema into as many graphql files as you like
│   └── schema.resolvers.go  - the resolver implementation for schema.graphql
└── server.go                - The entry point to your app. Customize it however you see fit
```

At this point, you can use `go run ./server.go` to fire up GraphQL server. gqlgen works with schema-first principle.
For code generation from GraphQL schema we need to run `go run github.com/99designs/gqlgen generate`. But there is a shorthand for it.

Add this line to top of your `gateway/graph/resolver.go` file (this method recommended in gqlgen docs). 

```go
//go:generate go run github.com/99designs/gqlgen

package graph

type Resolver struct {}
```

with this piece of code we can run `go generate ./...` in our command line and generate Go code from GraphQL schema.

gqlgen generates standard library compatible GraphQL server. You can use standard library http package or gorilla or chi routers. Personally I like to use [chi](https://github.com/go-chi/chi) router.

To install chi you can `go get -u github.com/go-chi/chi/v5` and for CORS `go get -u github.com/rs/cors`

The code generated with gqlgen init is using standard http package. Now, we'll connect chi router with gqlgen GraphQL server.

We will delete generated `server.go` file and create new file under `/cmd` folder:

```go
// gateway/cmd/main.go
package main

import (
  "log"
  "net/http"
  "os"

  "github.com/go-chi/chi/v5"
  "github.com/go-chi/chi/v5/middleware"
  "github.com/99designs/gqlgen/graphql/handler"
  "github.com/99designs/gqlgen/graphql/playground"
  "github.com/rs/cors"
)

func main() {
  port := os.Getenv("PORT")
  if port == "" {
    port = "3035"
  }

  srv := handler.NewDefaultServer(generated.NewExecutableSchema(generated.Config{Resolvers: &graph.Resolver{}}))

  r := chi.NewRouter()
	r.Use(cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowCredentials: true,
		Debug:            true,
	}).Handler)
  r.Use(middleware.Heartbeat("/readiness")) // for healthcheck
  
  r.Handle("/", playground.Handler("GraphQL playground", "/query"))
  r.Handle("/query", srv)

  log.Printf("Server is up and running on port %s\n", port)
  log.Fatal(http.ListenAndServe(":"+port, r))
}
```

Now for testing purposes we can alter our GraphQL schema with hello world message.

Edit graph/schema.graphqls file like below:

```graphql
type Query {
  sayHello: String!
}

type LoginResponse {
  id: ID!
  avatar: String!
  fullName: String!
  token: String!
}

type Mutation {
  login: LoginResponse!
}
```

Remove `graph/schema.resolvers.go` file content and run `go generate ./...` for code generation. This will update files below:

- graph/generated/generated.go
- graph/models/models_gen.go
- graph/schema.resolvers.go

We'll be working with `schema.resolvers.go` file. Update your schema resolver file like this:

```go
package graph

// This file will be automatically regenerated based on the schema, any resolver implementations
// will be copied through when generating and any unknown code will be moved to the end.

import (
	"context"

	"github.com/yigitsadic/fake_store/gateway/graph/generated"
	"github.com/yigitsadic/fake_store/gateway/graph/model"
)

func (r *mutationResolver) Login(ctx context.Context) (*model.LoginResponse, error) {
	res := model.LoginResponse{
		ID:       "21b00554672245329aa05a4596ec09c4",
		Avatar:   "https://avatars.dicebear.com/api/human/b9e73b73a19d4807b7fc518b0feeca24.svg",
		FullName: "Drew Schmidt",
		Token:    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdmF0YXIiOiJodHRwczovL2F2YXRhcnMuZGljZWJlYXIuY29tL2FwaS9odW1hbi9iOWU3M2I3M2ExOWQ0ODA3YjdmYzUxOGIwZmVlY2EyNC5zdmciLCJmdWxsTmFtZSI6IkRyZXcgU2NobWlkdCIsImV4cCI6MTY2MjczNDY5NzA0NjM4NzIwMCwianRpIjoiMjFiMDA1NTQ2NzIyNDUzMjlhYTA1YTQ1OTZlYzA5YzQiLCJpYXQiOjE2MzExOTg2OTcwNDY0MDUxMDAsImlzcyI6ImZha2Vfc3RvcmVfYXV0aCJ9.v6tYm0y7wD21G-Ec_1PMEmhnEf0WJMqdALzcWBbsX90",
	}

	return &res, nil
}

func (r *queryResolver) SayHello(ctx context.Context) (string, error) {
	return "Hello World", nil
}

// Mutation returns generated.MutationResolver implementation.
func (r *Resolver) Mutation() generated.MutationResolver { return &mutationResolver{r} }

// Query returns generated.QueryResolver implementation.
func (r *Resolver) Query() generated.QueryResolver { return &queryResolver{r} }

type mutationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }
```

Now we're ready to test our changes. In gateway folder run `go run ./cmd` and open [localhost:3035](http://localhost:3035) at your browser.

First fire up a query:

![first_query]({{site.baseurl}}/assets/img/2021_09_09_microservices/first_query.png)

And moment of truth. Let's try login mutation:

![first_mutation]({{site.baseurl}}/assets/img/2021_09_09_microservices/first_mutation.png)

We have successfully implemented basic GraphQL server in Go!

Let's move to Auth Service!

## Creating auth service

Root of your project folder, create new folder and initialize with proto file.

```
mkdir auth && cd auth
touch auth.proto
```

For protobuf you can visit [https://developers.google.com/protocol-buffers.](https://developers.google.com/protocol-buffers)

Update `auth.proto` file with:

```proto
syntax = "proto3";
package auth;

option go_package = "client/client";

message AuthRequest {}

message UserResponse {
  string id = 1;
  string avatar = 2;
  string fullName = 3;
  string jwtToken = 4;
}

service AuthService {
  rpc LoginUser(AuthRequest) returns (UserResponse) {}
}
```

For generate gRPC client and server generation we first need to install 

```
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.26
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1
```

```
protoc --go_out=. --go-grpc_out=. auth.proto
```

It will generate two files which contains models, client and server.
```
auth
  client
    client
      auth.pb.go
      auth_grpc.pb.go
```

In order to communicate using gRPC we need a server. Create a file named "auth/cmd/main.go"

I will use [faker](https://github.com/bxcodec/faker) package for random data generation. Install faker with `go get -u github.com/bxcodec/faker/v3`

For avatars I will use [dicebear](https://avatars.dicebear.com/) project. It gives you consistent random pretty avatars.
For generating JWT tokens, we need to install [github.com/dgrijalva/jwt-go](https://github.com/dgrijalva/jwt-go) with `go get -u github.com/dgrijalva/jwt-go`

Let's code JWT generation and gRPC server.

Create auth/cmd/jwt_token.go and insert codes below:

```go
package main

import (
	"github.com/dgrijalva/jwt-go"
	"time"
)

type Claims struct {
	Avatar   string `json:"avatar"`
	FullName string `json:"fullName"`
	jwt.StandardClaims
}

func GenerateJWTToken(id, avatar, fullName string) string {
	c := Claims{
		Avatar:   avatar,
		FullName: fullName,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: time.Now().AddDate(1, 0, 0).UnixNano(),
			Id:        id,
			IssuedAt:  time.Now().UnixNano(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, c)
	ss, _ := token.SignedString([]byte("FAKE_STORE_AUTH"))

	return ss
}
```

And for the auth/cmd/main.go file we're basicly initializing the most basic gRPC server:

```go
package main

import (
	"context"
	"fmt"
	"github.com/bxcodec/faker/v3"
	"github.com/yigitsadic/fake_store/auth/client/client"
	"google.golang.org/grpc"
	"log"
	"net"
)

const DiceBearUrl = "https://avatars.dicebear.com/api/human/%s.svg"

type Server struct {
	client.UnimplementedAuthServiceServer
}

func (s *Server) LoginUser(context.Context, *client.AuthRequest) (*client.UserResponse, error) {
	resp := client.UserResponse{
		Id:       faker.UUIDDigit(),
		Avatar:   fmt.Sprintf(DiceBearUrl, faker.UUIDDigit()),
		FullName: faker.FirstName() + " " + faker.LastName(),
	}
	resp.JwtToken = GenerateJWTToken(resp.Id, resp.Avatar, resp.FullName)

	return &resp, nil
}

func main() {
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", 9000))
	if err != nil {
		log.Fatalf("failed to listen: %v\n", err)
	}

	grpcServer := grpc.NewServer()
	s := Server{}

	client.RegisterAuthServiceServer(grpcServer, &s)

	log.Println("Started to serve auth grpc")
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("failed to serve due to %s\n", err)
	}
}
```

Our auth package almost ready. But we need to containerize it. Let's create Dockerfile.

```docker
FROM golang:1.17.0-alpine3.13 as compiler

WORKDIR /src/app

COPY go.mod go.sum ./

COPY auth auth

RUN go build -o auth_service ./auth/cmd/

FROM alpine:3.13

WORKDIR /src

COPY --from=compiler /src/app/auth_service /src/app
CMD ["/src/app"]
```

I created two-stepped dockerfile. At first step we compile our executable go code. At second step we run our executable in alpine image.

At this step our auth service is fullfil it's goals. It returns fake full-name along with a jwt token. I won't implement real auth logic and database operations here (sign-up, sign-in, verify password etc.)

## Connecting auth service from gateway

Let's import and use our gRPC client from gateway. That's the ease of protobuf and gRPC. Let's return to `gateway` folder.

gqlgen package tells us to we can use `Resolver` struct as a dependency injection purposes. I extend `gateway/graph/resolver.go` like below.

```go
//go:generate go run github.com/99designs/gqlgen

package graph

import "github.com/yigitsadic/fake_store/auth/client/client" // <- I am using client which generated from protobuf file.

type Resolver struct {
	AuthClient client.AuthServiceClient // <- AuthClient will be gRPC client to interact with auth service
}
```

Update `gateway/graph/schema.resolvers.go` for gRPC client use like below:

```go
// ...

func (r *mutationResolver) Login(ctx context.Context) (*model.LoginResponse, error) {
  // Make request to auth service
	result, err := r.AuthClient.LoginUser(ctx, &client.AuthRequest{})
	if err != nil {
		return nil, err
	}

  // Convert response into model.LoginResponse struct
	res := model.LoginResponse{
		ID:       result.Id,
		Avatar:   result.Avatar,
		FullName: result.FullName,
		Token:    result.JwtToken,
	}

	return &res, nil
}

// ...
```

From this point we connected resolver and we need to pass auth service client into resolver struct at initialization of GraphQL server.

Add client and connection generation function to main.go

```go

// gateway/cmd/main.go

func acquireAuthConnection() (*grpc.ClientConn, client.AuthServiceClient) {
	conn, err := grpc.Dial("auth:9000", grpc.WithInsecure(), grpc.WithBlock()) // auth:9000 We will be using docker-compose.
	if err != nil {
		log.Fatalln("Unable to acquire auth connection")
	}

	c := client.NewAuthServiceClient(conn)

	return conn, c
}
```

Let's update rest of `main.go` file.

```go
// package, import etc.

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "3035"
	}

  // acquire connection and pass resolver as dependency injection.
	authConnection, authClient := acquireAuthConnection()
	defer authConnection.Close()

	resolver := graph.Resolver{
		AuthClient: authClient,
	}

	srv := handler.NewDefaultServer(generated.NewExecutableSchema(generated.Config{Resolvers: &resolver}))

// Rest of code
```

Let's continue with Dockerfile.

Create Dockerfile with content:

```
FROM golang:1.17.0-alpine3.13 as compiler

WORKDIR /src/app

COPY go.mod go.sum ./

COPY gateway gateway
# We need this for access auth gRPC client
COPY auth auth

RUN go build -o gateway_service ./gateway/cmd/

FROM alpine:3.13

WORKDIR /src

COPY --from=compiler /src/app/gateway_service /src/app
CMD ["/src/app"]

```

Continue with docker-compose.yml file

```yaml
version: "3.3"

services:
  gateway:
    build:
      context: .
      dockerfile: ./gateway/Dockerfile
    ports:
      - "3035:3035"
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:3035/readiness" ]
      interval: 200s
      timeout: 200s
      retries: 5
  auth:
    build:
      context: .
      dockerfile: ./auth/Dockerfile
```

The moment of truth. Run `docker-compose up`

## What's next?

I will cover React app installation on [part II]({% post_url 2021-09-10-microservices-example-with-go-and-grpc-part-two %})

À la prochaine !
