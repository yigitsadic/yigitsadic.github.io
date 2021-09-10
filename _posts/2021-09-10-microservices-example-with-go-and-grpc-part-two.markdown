---
layout: post
title: "Microservice example application with Docker Swarm, Golang, gRPC, GraphQL, TypeScript and React - Part II"
date: 2021-09-09 19:30:00 +0300
categories: docker golang grpc typescript react microservices
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

TODO

## Handling page routing

TODO

## Installing react-redux

TODO

## Integrating with gateway via GraphQL

TODO

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

I will cover creation of products service and connecting it with gateway service and React app on part III.

À la prochaine !
