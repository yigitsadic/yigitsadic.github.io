---
layout: post
title: "Microservice example application with Docker Swarm, Golang, gRPC, GraphQL, TypeScript and React - Part III"
date: 2021-09-11 07:30:00 +0300
tags: docker golang grpc typescript react microservices
---

> This post will cover products service and connecting it with gateway service and React app.

## Updating GraphQL Schema and client integration

Let's start with updating our GraphQL schema like below:

```graphql

type Query {
  sayHello: String!
  products: [Product!] # new query
}

type Product {
  id: ID!
  title: String!
  description: String!
  price: Float!
  image: String!
}
```

and run gqlgen generator `go generate ./...` in `gateway` folder.

## Serving mock response for client


Update `gateway/graph/schema.resolvers.go` file for mock product list response:

```go
func (r *queryResolver) Products(ctx context.Context) ([]*model.Product, error) {
	products := []*model.Product{
		{
			ID:          "12e",
			Title:       "Camera",
			Description: "Basic camera",
			Price:       499.50,
			Image:       "https://via.placeholder.com/150",
		},
		{
			ID:          "24e",
			Title:       "Game console",
			Description: "Game console. Video games.",
			Price:       300.75,
			Image:       "https://via.placeholder.com/150",
		},
		{
			ID:          "43ert5",
			Title:       "Classical Novel",
			Description: "Classical novel that we all like",
			Price:       27,
			Image:       "https://via.placeholder.com/150",
		},
	}

	return products, nil
}
```

With this we can now serve mock response for our React app via GraphQL.

![product_list]({{site.baseurl}}/assets/img/2021_09_09_microservices/product-list.gif)

## Integrating with React

Change directory to `client` folder and run `yarn run start` to start-up webpack-dev-server.

Create `client/src/components/products` folder and `ProductDetail.tsx` and `ProductList.tsx` files following content:

```typescript
import React from "react";

const ProductDetail: React.FC = () => {
    return <div className="col">
        <div className="card shadow-sm">
            <img src="https://via.placeholder.com/150" />

            <div className="card-body">
                <p className="card-text">
                    Product description.
                </p>
                <div className="d-flex justify-content-between align-items-center">
                    <div className="btn-group">
                        <button type="button" className="btn btn-sm btn-outline-success">Add to Cart</button>
                    </div>
                </div>
            </div>
        </div>
    </div>;
}

export default ProductDetail;
```

```typescript
import React from "react";
import ProductDetail from "./ProductDetail";

const ProductsList: React.FC = () => {
    return <div className="album py-5 bg-light">
        <div className="container">
            <div className="row row-cols-1 row-cols-sm-5 row-cols-md-5 g-3">
                <ProductDetail />
                <ProductDetail />
                <ProductDetail />
                <ProductDetail />
                <ProductDetail />
            </div>
        </div>
    </div>;
}

export default ProductsList;
```

Use it in `App.tsx` file in routing switch:

```typescript
// .. rest of file

<Route path="/products">
    <ProductsList />
</Route>

// .. rest of file
```

We created basic mock product list like below:

![product_list]({{site.baseurl}}/assets/img/2021_09_09_microservices/product-list.png)

### Integrate with GraphQL

We need a query to list products. Let's create `product-query.ts` file under `products` folder.

```typescript
import { gql } from '@apollo/client';

export const PRODUCTS_QUERY = gql`
query listProducts {
    products {
        id
        title
        description
        price
        image
    }
}
`;
```

After this run `yarn run codegen` to generate query hook for it.

Modify `ProductList` component like below:

```typescript
import React from "react";
import ProductDetail from "./ProductDetail";
import {useListProductsQuery} from "../../generated/graphql";

const ProductsList: React.FC = () => {
    const {data, loading, error} = useListProductsQuery();

    if (loading) return <h3>Loading...</h3>;
    if (error) return <h3>Error occurred during displaying products. Please try again.</h3>

    if (data && data.products) {
        return <div className="album py-5 bg-light">
            <div className="container">
                <div className="row row-cols-1 row-cols-sm-5 row-cols-md-5 g-3">
                    {data.products.map(product => <ProductDetail key={product.id} product={product} /> )}
                </div>
            </div>
        </div>;
    }

    return <h3>Error occurred during displaying products. Please try again.</h3>
}

export default ProductsList;
```

We need to modify `ProductDetail` component in order to show product.

```typescript
import React from "react";
import {useAppSelector} from "../../store/hooks";
import {selectedCurrentUser} from "../../store/auth/auth";

interface ProductProps {
    id: string,
    title: string,
    description: string,
    price: number,
    image: string
}
interface ProductDetailProps {
    product: ProductProps;
}

const ProductDetail: React.FC<ProductDetailProps> = ({ product }: ProductDetailProps) => {
    const currentUser = useAppSelector(selectedCurrentUser); // for disabling unauthorized users clicking add to cart

    return <div className="col">
        <div className="card shadow-sm">
            <img src={product.image} alt={product.title} />

            <div className="card-body">
                <p className="card-title">{product.title}</p>

                <p className="card-text">
                    {product.description}
                </p>
                <div className="d-flex justify-content-between align-items-center">
                    <div className="btn-group">
                        <button type="button"
                                className="btn btn-sm btn-outline-success"
                                disabled={!currentUser.loggedIn}>
                            Add to Cart
                        </button>
                    </div>

                    <small className="text-muted">{product.price} EUR</small>
                </div>
            </div>
        </div>
    </div>;
}

export default ProductDetail;
```

Result is nice. We connected our React app to GraphQL server. Now we need to create product service and connect it to gateway.

![product_list]({{site.baseurl}}/assets/img/2021_09_09_microservices/product-list-graphql.png)


## Creating products service

In project's root directory create folder called `products` Inside products folder create `product.proto` file.

```protobuf
syntax = "proto3";
package products;

option go_package = "product_grpc/product_grpc";

message ProductListRequest {}

message Product {
  string id = 1;
  string title = 2;
  string description = 3;
  float  price = 4;
  string image = 5;
}

message ProductList {
  repeated Product products = 1;
}

service ProductService {
  rpc ListProducts(ProductListRequest) returns (ProductList) {}
}
```

This describes our product server's communication with gateway. To generate client and server run `protoc --go_out=. --go-grpc_out=. products.proto` inside `fake_store/products` folder. Create `cmd/main.go` and `cmd/server.go` files to serve product service.

```go
// products/cmd/server.go

package main

import (
	"context"
	"github.com/yigitsadic/fake_store/products/product_grpc/product_grpc"
)

type server struct {
	product_grpc.UnimplementedProductServiceServer
}

func (s *server) ListProducts(context.Context, *product_grpc.ProductListRequest) (*product_grpc.ProductList, error) {
	products := []*product_grpc.Product{{
		Id:          "825c2ca8-cfeb-4ba4-8b34-fb93f7958fa8",
		Title:       "Cornflakes",
		Price:       6.94,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "46541671-d9dd-4e99-9f40-c807e1b14f11",
		Title:       "Vaccum Bag - 14x20",
		Price:       4.97,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "c3af5841-4cfe-4ba0-874b-7c8ced576357",
		Title:       "Mustard - Dijon",
		Price:       1.25,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "966a9098-3252-4a43-9776-dd7f66e09d91",
		Title:       "Cheese - Le Cru Du Clocher",
		Price:       1.69,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "0fef08f2-cc56-4fd7-9137-b0ab561bc7a1",
		Title:       "Beef - Striploin",
		Price:       2.71,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "9f932b92-3433-4be2-8302-7ac4901c97d6",
		Title:       "Beef - Bones, Marrow",
		Price:       8.73,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "6bf9959e-cf2c-4039-9a31-30a9e90e8d7c",
		Title:       "V8 Pet",
		Price:       6.61,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "4f2a902a-446f-41da-9d12-521f9c83c94a",
		Title:       "Sauce - Fish 25 Ozf Bottle",
		Price:       2.49,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "3497030f-7239-4fce-bb73-f446e4fedc10",
		Title:       "Beef - Rib Eye Aaa",
		Price:       6.38,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "49d5f82e-d636-4d6c-8508-5429db7fd4b1",
		Title:       "Muffin Mix - Banana Nut",
		Price:       5.68,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "ee66f7e3-4bdd-4298-b790-43a2431c77ab",
		Title:       "Dawn Professionl Pot And Pan",
		Price:       4.89,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "992d3766-6022-4ee1-847e-f293f2488951",
		Title:       "Jameson - Irish Whiskey",
		Price:       1.12,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "95ca1986-9e39-485e-942e-927ac91aecde",
		Title:       "Bread Fig And Almond",
		Price:       2.58,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "eb46937c-12f5-4b9b-8ffa-7cf20871fbaf",
		Title:       "Vinegar - White",
		Price:       4.16,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}, {
		Id:          "c03020f2-fbf2-463d-9003-15e1901dc47a",
		Title:       "Bouq All Italian - Primerba",
		Price:       4.33,
		Description: "Lorem ipsum dolor sit amet",
		Image:       "https://via.placeholder.com/150",
	}}

	return &product_grpc.ProductList{
		Products: products,
	}, nil
}
```

```go
// products/cmd/main.go
package main

import (
	"fmt"
	"github.com/yigitsadic/fake_store/products/product_grpc/product_grpc"
	"google.golang.org/grpc"
	"log"
	"net"
)

func main() {
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", 9000))
	if err != nil {
		log.Fatalf("failed to listen: %v\n", err)
	}

	grpcServer := grpc.NewServer()
	s := server{}

	product_grpc.RegisterProductServiceServer(grpcServer, &s)

	log.Println("Started to serve product grpc")
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("failed to serve due to %s\n", err)
	}
}
```

And we need a dockerfile. It's copy & paste at this moment.

```dockerfile
FROM golang:1.17.0-alpine3.13 as compiler

WORKDIR /src/app

COPY go.mod go.sum ./

COPY products products

RUN go build -o product_service ./products/cmd/

FROM alpine:3.13

WORKDIR /src

COPY --from=compiler /src/app/product_service /src/app
CMD ["/src/app"]
```

## Connecting products service with gateway

In `gateway/graph` folder find `resolver.go` and add product service client to Resolver as dependency.

```go
//go:generate go run github.com/99designs/gqlgen

package graph

import (
	"github.com/yigitsadic/fake_store/auth/client/client"
	"github.com/yigitsadic/fake_store/products/product_grpc/product_grpc"
)

type Resolver struct {
	AuthClient     client.AuthServiceClient
	ProductsClient product_grpc.ProductServiceClient // Product service
}
```

And in `schema.resolvers.go` file change Products like below:

```go
// rest of file
func (r *queryResolver) Products(ctx context.Context) ([]*model.Product, error) {
	var products []*model.Product

	productResp, err := r.ProductsClient.ListProducts(ctx, nil)
	if err != nil {
		return nil, err
	}

	for _, product := range productResp.Products {
		products = append(products, &model.Product{
			ID:          product.Id,
			Title:       product.Title,
			Description: product.Description,
			Price:       float64(product.Price),
			Image:       product.Image,
		})
	}

	return products, nil
}
// rest of file
```

In initialization, let's add client to resolver:

```go
// gateway/cmd/main.go

productsConnection, productClient := acquireProductsConnection()
defer productsConnection.Close()

resolver := graph.Resolver{
    AuthClient:     authClient,
    ProductsClient: productClient, // our new service
}

// bottom of file
func acquireProductsConnection() (*grpc.ClientConn, product_grpc.ProductServiceClient) {
	conn, err := grpc.Dial("products:9000", grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalln("Unable to acquire products connection")
	}

	c := product_grpc.NewProductServiceClient(conn)

	return conn, c
}
```

We need to update gateway service's Dockerfile too:

```dockerfile
COPY products products
```

## Adding service to swarm

Add products service to `docker-compose.yml` and run `docker-compose build` and `docker-compose up`

```yml
  products:
    build:
      context: .
      dockerfile: ./products/Dockerfile
```

With this refactor we can see products from products service. But there is a small problem. Products' prices look bad but I don't care it right now.

![product_list]({{site.baseurl}}/assets/img/2021_09_09_microservices/products-from-product-service.png)

## What's next?

I will cover cart service and connecting it with gateway service and React app on part IV.

À la prochaine !
