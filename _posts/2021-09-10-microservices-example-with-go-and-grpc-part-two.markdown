---
layout: post
title: "Microservice example application with Docker Swarm, Golang, gRPC, GraphQL, TypeScript and React - Part II"
date: 2021-09-09 19:30:00 +0300
tags: docker golang grpc typescript react microservices
---

> This post will cover creation of React app creation, installation of dependencies and logging via GraphQL.

## Client React app

At this step I followed steps of this blog [post.](https://dev.to/deadwing7x/setup-a-react-app-using-webpack-babel-and-typescript-5927)
First, I will create a folder named "client" and initialize with `yarn init -y`.

Install dependencies:

```
yarn add -D typescript @types/react @types/react-dom @babel/preset-typescript ts-loader @babel/core @babel/preset-env @babel/preset-react babel-loader css-loader file-loader html-webpack-plugin path webpack webpack-cli webpack-dev-server
yarn add react react-dom
```

Create `webpack.config.js` with following:

```javascript
const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = {
  entry: "./src/index.tsx",
  output: { path: path.join(__dirname, "build"), filename: "index.bundle.js" },
  mode: process.env.NODE_ENV || "development",
  resolve: {
    extensions: [".tsx", ".ts", ".js"],
  },
  devServer: {
    compress: true,
    port: 9000
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: ["babel-loader"],
      },
      {
        test: /\.(ts|tsx)$/,
        exclude: /node_modules/,
        use: ["ts-loader"],
      },
      {
        test: /\.(css|scss)$/,
        use: ["style-loader", "css-loader"],
      },
      {
        test: /\.(jpg|jpeg|png|gif|mp3|svg)$/,
        use: ["file-loader"],
      },
    ],
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: path.join(__dirname, "src", "index.html"),
    }),
  ],
};

```

Initialize `.babelrc` file:

```javascript
{
    "presets": [
        "@babel/env",
        "@babel/react",
        "@babel/preset-typescript"
    ],
    "plugins": [
        "@babel/plugin-proposal-class-properties"
    ]
}
```

Create `tsconfig.json` with following content:

```json
{
    "compilerOptions": {
        "target": "es5",
        "lib": [
            "dom",
            "dom.iterable",
            "esnext"
        ],
        "allowJs": true,
        "skipLibCheck": true,
        "esModuleInterop": true,
        "allowSyntheticDefaultImports": true,
        "strict": true,
        "forceConsistentCasingInFileNames": true,
        "noFallthroughCasesInSwitch": true,
        "module": "esnext",
        "moduleResolution": "node",
        "resolveJsonModule": true,
        "isolatedModules": true,
        "noEmit": false,
        "jsx": "react-jsx"
    },
    "include": [
        "src"
    ]
}
```

Create `src` folder with following files:

```html
<!-- index.html -->
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1, shrink-to-fit=no"
    />
    <meta name="theme-color" content="#000000" />
    <title>Fake Store</title>
  </head>
  <body>
    <noscript> You need to enable JavaScript to run this app. </noscript>
    <div id="root"></div>
  </body>
</html>
```

```typescript
// index.tsx

import React from "react";
import ReactDOM from "react-dom";
import App from "./App";

ReactDOM.render(
    <React.StrictMode>
        <App />
    </React.StrictMode>,
    document.getElementById("root")
);
```

```typescript
import React from "react";

const App: React.FC = () => {
    return (
        <div>
            Hello World
        </div>
    );
};

export default App;
```

Final folder structure will look like this:

```
client/
  src/
    index.tsx
    App.tsx
    index.html
  .babelrc
  package.json
  tsconfig.json
  webpack.config.json
  yarn.lock
```

Finally update `package.json` like this:

```json
/* rest of package.json */
  "scripts": {
    "start": "webpack serve",
    "build": "webpack"
  }
```

Let's try `yarn run start` and open [http://localhost:9000](http://localhost:9000/) at browser. We should see Hello World text.

Great success. We successfully connected TypeScript, React and webpack. 

## Installing bootstrap

I decided to use Bootsrap 5 in this project. To install, run: `yarn add bootstrap` In your `src/index.tsx` file add import to top:

```typescript

import React from "react";
import ReactDOM from "react-dom";
import App from "./App";

import 'bootstrap/dist/css/bootstrap.min.css';

// ...
```

In `App.tsx` file let's add CSS class to main div:

```typescript
import React from "react";

const App: React.FC = () => {
    return (
        <div className="container-fluid">
            Hello World
        </div>
    );
};

export default App;
```

Create `src/components/nav-bar/NavBar.tsx` file for navigation.

```typescript
import React from "react";
import Links from "./Links";
import AuthArea from "./auth-area/AuthArea";

const NavBar: React.FC = () => {
    return (
        <nav className="navbar navbar-expand-md navbar-dark bg-dark mb-4">
            <div className="container-fluid">
                <a href="/" className="navbar-brand">Fake Store</a>

                <button className="navbar-toggler" type="button" data-bs-toggle="collapse"
                        data-bs-target="#navbarCollapse" aria-controls="navbarCollapse" aria-expanded="false"
                        aria-label="Toggle navigation">
                    <span className="navbar-toggler-icon"></span>
                </button>
                <div className="collapse navbar-collapse" id="navbarCollapse">
                    <Links />
                </div>
            </div>
        </nav>
    );
};

export default NavBar;
```

We used Links component which is not defined at this moment. Continue with defining them:


```typescript
// src/components/nav-bar/Links.tsx

import React from "react";

const Links: React.FC = () => {
    return (
        <ul className="navbar-nav me-auto mb-2 mb-md-0">
            <li className="nav-item">
                <a href="/products" className="nav-link">Products</a>
            </li>

            <li className="nav-item">
                <a href="/orders" className="nav-link">Orders</a>
            </li>

            <li className="nav-item">
                <a href="/cart" className="nav-link">Cart</a>
            </li>
        </ul>
    )
};

export default Links;
```

We basicly connected Bootstrap to our React application. Next step we'll connect React router. Let's go.

## Handling page routing

Let's start by installing `yarn add react-router-dom`. We need to set a provider top of component:

In `src/index.tsx` wrap <App /> with `BrowserRouter` component.
```typescript
import React from "react";
import ReactDOM from "react-dom";
import App from "./App";

import 'bootstrap/dist/css/bootstrap.min.css';
import {BrowserRouter} from "react-router-dom";

ReactDOM.render(
    <React.StrictMode>
      <BrowserRouter>
          <App />
      </BrowserRouter>
    </React.StrictMode>,
    document.getElementById("root")
);
```

We need to provide routes in our `src/App.tsx` file like below:

```typescript
import React from "react";
import NavBar from "./components/nav-bar/NavBar";
import {Route, Switch} from "react-router-dom";

const App: React.FC = () => {
    return (
        <>
            <NavBar />

            <div className="container-fluid">
                <Switch>
                    <Route path="/products">
                        Products
                    </Route>

                    <Route path="/orders">
                        Orders
                    </Route>

                    <Route path="/cart">
                        Cart
                    </Route>

                    <Route path="/">
                        Home
                    </Route>
                </Switch>
            </div>
        </>
    );
};

export default App;
```

Let's convert anchor tags to <Link> components in files:

* components/NavBar.tsx
* components/Links.tsx

```typescript
// Links.tsx
import React from "react";

import  { Link } from "react-router-dom";

const Links: React.FC = () => {
    return (
        <ul className="navbar-nav me-auto mb-2 mb-md-0">
            <li className="nav-item">
                <Link to="/products" className="nav-link">Products</Link>
            </li>

            <li className="nav-item">
                <Link to="/orders" className="nav-link">Orders</Link>
            </li>

            <li className="nav-item">
                <Link to="/cart" className="nav-link">Cart</Link>
            </li>
        </ul>
    )
};

export default Links;
```

```typescript
// ..
<Link to="/" className="navbar-brand">Fake Store</Link>
// rest of code
```

Routing is completed at this moment. Let's integrate react-redux in order to handle states which is we need for authentication and cart managemennt.

## Installing react-redux

```
yarn add -D @types/react-redux
yarn add @reduxjs/toolkit react-redux
```

We will use react-redux via hooks. I will create auth store handler now but first let's create store folder structure below:

```
app/
  store/
    hooks.ts
    store.ts
    auth/
      auth.ts
      user.ts
```

Let's create user interface first in `store/auth/user.ts`

```typescript
export interface User {
    id?: string;
    avatar?: string;
    fullName?: string;

    loggedIn: boolean;
}
```

Let's continue with reducers and selector:

```typescript
// store/auth/auth.ts

import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import {User} from "./user";
import {RootState} from "../store";

export interface AuthState {
    user: User,
}

const initialState: AuthState = {
    user: {
        loggedIn: false,
    },
};

export const authSlice = createSlice({
    name: "auth-handler",
    initialState,
    reducers: {
        login: (state, action: PayloadAction<User>) => {
            state.user = action.payload;
        },
        logout: (state) => {
            state.user = { loggedIn: false };
        },
    },
});

export const { login, logout } = authSlice.actions;
export const selectedCurrentUser = (state: RootState) => state.auth.user;

export default authSlice.reducer;

```

Let's define hooks:

```typescript
// store/hooks.ts

import { TypedUseSelectorHook, useDispatch, useSelector } from 'react-redux';
import type { RootState, AppDispatch } from './store';

export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
```

Let's finish with store.ts:

```typescript
// store/store.ts

import { configureStore } from '@reduxjs/toolkit';
import authReducer from "./auth/auth";

export const store = configureStore({
    reducer: {
        auth: authReducer,
    },
});

export type AppDispatch = typeof store.dispatch;
export type RootState = ReturnType<typeof store.getState>;
```

Our store/ folder is ready, the final step is connect it via store provider in `index.tsx` file:

```typescript
// imports
import {Provider} from "react-redux";
import {store} from "./store/store";
// imports

ReactDOM.render(
    <React.StrictMode>
        <Provider store={store}> // react-redux provider
            <BrowserRouter>
                <App />
            </BrowserRouter>
        </Provider>
    </React.StrictMode>,
    document.getElementById("root")
);
```

Integration finished. I will add login/logout switch right now.

In `src/components/nav-bar` folder create `auth-area` with following files:

```
- AuthArea.tsx
- AuthenticatedUser.tsx
- Unauthenticated.tsx
```

Let's start with `AuthArea.tsx`. This component will be root point for handling login & logout operations.

```typescript
// src/components/nav-bar/auth-area/AuthArea.tsx
import React from "react";
import AuthenticatedUser from "./AuthenticatedUser";
import Unauthenticated from "./Unauthenticated";
import {useAppSelector} from "../../../store/hooks";
import {selectedCurrentUser} from "../../../store/auth/auth";

const AuthArea: React.FC = () => {
    const { loggedIn } = useAppSelector(selectedCurrentUser);

    return loggedIn ? <AuthenticatedUser /> :  <Unauthenticated />;
}

export default AuthArea;
```

Continue with `Authenticated.tsx`

```typescript
import React from "react";
import {logout, selectedCurrentUser} from "../../../store/auth/auth";
import {useAppDispatch, useAppSelector} from "../../../store/hooks";

const AuthenticatedUser: React.FC = () => {
    const dispatch = useAppDispatch();
    const currentUser = useAppSelector(selectedCurrentUser);

    return <>
        <button type="button" className="btn btn-primary position-relative">
            <img src={currentUser?.avatar} width="20px" height="20px" /> &nbsp;&nbsp;
            {currentUser?.fullName}
        </button>

        <button type="button"
                className="btn btn-danger position-relative"
                onClick={() => dispatch(logout())}>
            Logout
        </button>
    </>;
}

export default AuthenticatedUser;
```

Let's move into `Unauthenticated.tsx`

```typescript
import React from "react";
import {login} from "../../../store/auth/auth";
import {useAppDispatch} from "../../../store/hooks";

const Unauthenticated: React.FC = () => {
    const dispatch = useAppDispatch();

    return <>
        <button
            type="button"
            className="btn btn-outline-success"
            onClick={() => {
                dispatch(login({
                    id: "1231231",
                    fullName: "Georges Brassens",
                    avatar: "georges-brassens.svg",
                    loggedIn: true,
                }));
            }}
        >
            Login
        </button>
    </>;
};

export default Unauthenticated;
```

The final step is refer `AuthArea` component in `NavBar` component.

```typescript
// .. rest of src/nav-bar/NavBar.tsx file

<div className="collapse navbar-collapse" id="navbarCollapse">
    <Links />
    <AuthArea />
</div>

// .. rest of src/nav-bar/NavBar.tsx file
```

## Integrating with gateway via GraphQL

I will use code generation tool for creating hooks for queries and mutations.

```
yarn add -D @graphql-codegen/cli @graphql-codegen/typescript @graphql-codegen/typescript-operations @graphql-codegen/typescript-react-apollo @types/graphql
yarn add graphql @apollo/client
```

Create config file for codegen named `codegen.yml`

```yaml
overwrite: true
schema: "http://localhost:3035/query"
documents: "./src/components/**/*.{ts,tsx}"
generates:
  ./src/generated/graphql.tsx:
    plugins:
      - "typescript"
      - "typescript-operations"
      - "typescript-react-apollo"
    config:
      withHooks: true
```

For schema introspection we need to fire-up gateway service via `docker-compose up`

codegen will look for /src/components sub directories and files. Let's create first mutation.

```typescript
// src/components/nav-bar/auth-area/mutation.ts

import { gql } from '@apollo/client';

export const LOGIN_MUTATION = gql`
    mutation login {
        login {
            id
            avatar
            fullName
            token
        }
    }
`;
```

Add code below to package.json file
```json
  "scripts": {
    "start": "webpack serve",
    "build": "webpack",
    "codegen": "graphql-codegen --config codegen.yml"
  }
```

And run `yarn run codegen` and voilà ! We generated GraphQL hooks in TypeScript.

Let's use them in `Unauthenticated` component. Final form will look like this:

```typescript
import React from "react";
import {useLoginMutation} from "../../../generated/graphql";
import {login} from "../../../store/auth/auth";
import {useAppDispatch} from "../../../store/hooks";

const Unauthenticated: React.FC = () => {
    const dispatch = useAppDispatch();
    const [loginUser, {data, loading, error}] = useLoginMutation();

    if (data) {
        dispatch(login({
            id: data.login.id,
            fullName: data.login.fullName,
            avatar: data.login.avatar,
            loggedIn: true,
        }));
    }

    return <>
        <button
            type="button"
            className="btn btn-outline-success"
            onClick={() => loginUser()}
            disabled={loading}
        >
            {error ? "Error occurred - Retry" : (loading ? "Loading..." : "Login")}
        </button>
    </>;
};

export default Unauthenticated;
```

We need to set provider for GraphQL server at `index.tsx` file.
```typescript
import React from "react";
import ReactDOM from "react-dom";
import App from "./App";

import 'bootstrap/dist/css/bootstrap.min.css';
import {ApolloClient, ApolloProvider, InMemoryCache} from "@apollo/client";
import {Provider} from "react-redux";
import {BrowserRouter} from "react-router-dom";
import {store} from "./store/store";

const client = new ApolloClient({
    uri: 'http://localhost:3035/query',
    cache: new InMemoryCache(),
});

ReactDOM.render(
    <React.StrictMode>
        <Provider store={store}>
            <ApolloProvider client={client}>
                <BrowserRouter>
                    <App />
                </BrowserRouter>
            </ApolloProvider>
        </Provider>
    </React.StrictMode>,
    document.getElementById("root")
);
```

That's it. We connected React app into GraphQL server with generated hooks.

![error_state]({{site.baseurl}}/assets/img/2021_09_09_microservices/err.gif)
![successful]({{site.baseurl}}/assets/img/2021_09_09_microservices/suc.gif)

## Containerization

We can move into Dockerfile now.

```
FROM node:16.0.0-alpine3.13 as compiler

WORKDIR /app/src

COPY ./client/package.json package.json
COPY ./client/yarn.lock yarn.lock

RUN yarn install

COPY client client

ENV NODE_ENV=production
RUN cd client && yarn run build

FROM nginx:alpine

COPY --from=compiler /app/src/client/build /usr/share/nginx/html
```

That's the most basic version of single page application. Dockerfile contains two steps: First we compile our TypeScript into JavaScript and HTML with WebPack.
At last step we copy static assets to nginx image and serve them. They're JavaScript, HTML and CSS at this moment.

`docker-compose.yml` file look like this at this point:

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
  client:
    build:
      context: .
      dockerfile: ./client/Dockerfile
    ports:
      - "3000:80"
    depends_on:
      - gateway
```

## What's next?

I will cover creation of products service and connecting it with gateway service and React app on
[part III]({% post_url 2021-09-11-microservices-example-with-go-and-grpc-part-three %})

À la prochaine !
