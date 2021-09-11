---
layout: post
title: "Microservice example application with Docker Swarm, Golang, gRPC, GraphQL, TypeScript and React - Part III"
date: 2021-09-11 07:30:00 +0300
categories: docker golang grpc typescript react microservices
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

TODO

## Connecting products service with gateway

TODO

## Adding service to swarm

TODO

## What's next?

I will cover cart service and connecting it with gateway service and React app on part IV.

À la prochaine !
