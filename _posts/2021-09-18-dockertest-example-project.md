---
layout: post
title: An example project for running both unit tests and integration tests.
date: 2021-09-18 15:00:00 +03000
tags: docker golang test
---

> You can find this repo at [github.com/yigitsadic/listele](https://github.com/yigitsadic/listele)

I will develop a basic person listing application with [dockertest](https://github.com/ory/dockertest) testify and postgres.

First of all let's create project folder and init as go module.

```
mkdir listele
cd listele

go mod init github.com/yigitsadic/listele
```

Let's start with create something we can see.

I will use [fiber](https://github.com/gofiber/fiber) at this example project.

```
go get -u github.com/gofiber/fiber/v2
```

I will create `main.go` file with the most basic setup.

```go
package main

import "github.com/gofiber/fiber/v2"

func main() {
	app := fiber.New()

	app.Get("/", func(ctx *fiber.Ctx) error {
		return ctx.JSON(map[string]string{
			"message": "Hello World",
		})
	})

	app.Listen(":3035")
}
```

At this point we can see basic hello world message if we `curl http://localhost:3035`

```json
{"message":"Hello World"}
```

# Creating repository interface

I will store database related codes under database package. I will start with repository.

```go
// database/repository.go

package database

// Person represents database row for people table.
type Person struct {
	FullName string `json:"full_name"`
}

// Repository is an interface for communicating between handler and database
type Repository interface {
	FindAll() ([]Person, error)
}
```

As we can see here, we have `Person` struct simply represents database row only have full name.

Let's continue with writing tests for listing handlers. I will store handler related codes under `handlers` package.

But first we need to install [testify](https://github.com/stretchr/testify) for tests.

```
go get github.com/stretchr/testify
```

```go
// handlers/handlers_test.go

package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"net/http"
	"testing"
)

func TestHandleList(t *testing.T) {
	t.Run("it should list records", func(t *testing.T) {
		app := fiber.New()
		app.Get("/", HandleList()) // we have no HandleList() function right now.

		req, err := http.NewRequest(http.MethodGet, "/", nil)
		require.Nil(t, err, "unexpected to get an error")

		res, err := app.Test(req, -1)
		assert.Nil(t, err, "unexpected to get an error")

		assert.Equalf(t, http.StatusOK, res.StatusCode, "expected to get status ok but got=%d", res.StatusCode)
		assert.Equal(t, fiber.MIMEApplicationJSON, res.Header.Get("Content-Type"))
	})
}
```

As you can see if we `go test ./handlers` we will get 

```
...
handlers/handlers_test.go:14:16: undefined: HandleList
...
```

We need to provide handler for this test to run.

```go
// handlers/handlers.go

package handlers

import "github.com/gofiber/fiber/v2"

func HandleList() func(ctx *fiber.Ctx) error {
	return func(ctx *fiber.Ctx) error {
		return ctx.JSON(map[string]string{
			"message": "Hello from handler",
		})
	}
}
```

With this minimal setup our tests will pass.

```
go test ./handlers
ok      github.com/yigitsadic/listele/handlers        0.898s
```

#  Adding second test

Let's connect our `Repository` interface and test failure scenario.

Update `handlers_test.go` file like below:

```go

package handlers

import (
	"errors"
	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/yigitsadic/listele/database"
	"net/http"
	"testing"
)

// Testing repository struct that follows repository interface
type testRepository struct {
	ReturnErrorOnFindAll bool
}

func (g *testRepository) FindAll() ([]database.Person, error) {
	if g.ReturnErrorOnFindAll {
		return nil, errors.New("some error occurred")
	}

	return []database.Person{
		{
			FullName: "John Doe",
		},
	}, nil
}

func TestHandleList(t *testing.T) {
	t.Run("it should list records", func(t *testing.T) {
		repo := &testRepository{ReturnErrorOnFindAll: false}

		app := fiber.New()
		app.Get("/", HandleList(repo)) // inserted in-memory repository mocks database calls.

		req, err := http.NewRequest(http.MethodGet, "/", nil)
		require.Nil(t, err, "unexpected to get an error")

		res, err := app.Test(req, -1)
		assert.Nil(t, err, "unexpected to get an error")

		assert.Equalf(t, http.StatusOK, res.StatusCode, "expected to get status ok but got=%d", res.StatusCode)
		assert.Equal(t, fiber.MIMEApplicationJSON, res.Header.Get("Content-Type"))
	})

	t.Run("it should return internal server error if anything goes wrong", func(t *testing.T) {
		testRepo := &testRepository{ReturnErrorOnFindAll: true}

		app := fiber.New()
		app.Get("/", HandleList(testRepo)) // inserted in-memory repository mocks database calls.

		req, err := http.NewRequest(http.MethodGet, "/", nil)
		require.Nil(t, err, "unexpected to get an error")

		res, err := app.Test(req, -1)
		assert.Nil(t, err, "unexpected to get an error")

		assert.Equalf(t, http.StatusInternalServerError, res.StatusCode, "expected to get internal server error but got=%d", res.StatusCode)
	})
}
```

As you can see, we have a mock struct that follows `Repository` interface. We can configure mock struct to give an error or return list of people.

But our handler does not accepts `Repository` typed argument right now. Let's run tests and see:

```
# github.com/yigitsadic/listele/handlers [github.com/yigitsadic/listele/handlers.test]
handlers/handlers_test.go:34:26: too many arguments in call to HandleList
        have (*testRepository)
        want ()
handlers/handlers_test.go:50:26: too many arguments in call to HandleList
        have (*testRepository)
        want ()
FAIL    github.com/yigitsadic/listele/handlers [build failed]
FAIL
```

Let's edit our handler.

```go
package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/yigitsadic/listele/database"
)

// We added Repository interface as parameter.
func HandleList(repo database.Repository) func(ctx *fiber.Ctx) error {
	return func(ctx *fiber.Ctx) error {
		return ctx.JSON(map[string]string{
			"message": "Hello from handler",
		})
	}
}
```

We added Repository interface as parameter. It now compiles but our tests still failing.

```
--- FAIL: TestHandleList (0.00s)
    --- FAIL: TestHandleList/it_should_return_internal_server_error_if_anything_goes_wrong (0.00s)
        handlers_test.go:58: 
                Error Trace:    handlers_test.go:58
                Error:          Not equal: 
                                expected: 500
                                actual  : 200
                Test:           TestHandleList/it_should_return_internal_server_error_if_anything_goes_wrong
                Messages:       expected to get internal server error but got=200
FAIL
FAIL    github.com/yigitsadic/listele/handlers        0.134s
FAIL
```

We expected 500 Internal server error when something gone wrong scenario but we got 200 status ok.

Let's write the code satisfies our tests.

```go
// handlers/handlers.go

package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/yigitsadic/listele/database"
)

// HandleList handles listing data taken from repository.
func HandleList(repo database.Repository) func(ctx *fiber.Ctx) error {
	return func(ctx *fiber.Ctx) error {
		people, err := repo.FindAll()
		if err != nil {
			return ctx.SendStatus(fiber.StatusInternalServerError)
		}

		return ctx.JSON(people)
	}
}
```

Now our tests are passing for handlers.

So far we completed implementation of listing people records that we fetched from given repository.

Let's continue with integration tests.



# Database integration

I will use [golang migrate](https://github.com/golang-migrate/migrate) for migrating our database and for database I will choose postgres.

Let's go.

Install golang migrate:

```
go get github.com/golang-migrate/migrate/v4
go get github.com/lib/pq
```

Continue with installing [dockertest](https://github.com/ory/dockertest):

```
go get -u github.com/ory/dockertest/v3
```

Before we start to testing, we need basic migrations for table creation and seeding that table.

I will create `db` folder under root of project and create migration files:

```
listele/
  database/
    repository.go
  handlers/
    handlers.go
    handlers_test.go
  go.mod
  go.sum
  main.go
  db/
    migrations/
      000001_create_people_table.down.sql
      000001_create_people_table.up.sql
      000002_seed_people_table.down.sql
      000002_seed_people_table.up.sql
```

For first migration, let's create `people` table

```sql
CREATE TABLE IF NOT EXISTS people(
    id serial PRIMARY KEY,
    fullName VARCHAR (70) NOT NULL
);
```

for down.sql

```sql
DROP TABLE IF EXISTS people;
```

For the seed migration I will insert four records into people table:

```sql
INSERT INTO people(fullname) VALUES ('John Doe');
INSERT INTO people(fullname) VALUES ('Aida Bugg');
INSERT INTO people(fullname) VALUES ('Maureen Biologist');
INSERT INTO people(fullname) VALUES ('Allie Grater');
```

For rollback I will simply delete all records in people table:

```sql
DELETE FROM people WHERE 1=1;
```

# Running postgres image in test

I will create `people_test.go` under database package.

```go
package database

import (
	"database/sql"
	"fmt"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	"github.com/ory/dockertest/v3"
	"github.com/stretchr/testify/assert"
	"log"
	"os"
	"testing"
	"time"

	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
)

var db *sql.DB

func TestMain(m *testing.M) {
	pool, err := dockertest.NewPool("")
	if err != nil {
		log.Fatalf("Could not connect to docker: %s", err)
	}

	user := "myexampleuser"
	password := "myexample"
	dbName := "listele"

	// runs postgres image
	resource, err := pool.Run("postgres", "13.4-alpine", []string{
		fmt.Sprintf("POSTGRES_PASSWORD=%s", password),
		fmt.Sprintf("POSTGRES_USER=%s", user),
		fmt.Sprintf("POSTGRES_DB=%s", dbName),
	})
	if err != nil {
		log.Fatalf("Could not connect to docker: %s", err)
	}

	// tries to connect postgres via connection string with retry.
	if err = pool.Retry(func() error {
		var errOpenConn error

		db, errOpenConn = sql.Open("postgres", fmt.Sprintf("postgres://%s:%s@localhost:%s/%s?sslmode=disable", user, password, resource.GetPort("5432/tcp"), dbName))
		if errOpenConn != nil {
			return errOpenConn
		}
		return db.Ping()
	}); err != nil {
		log.Fatalf("Could not connect to docker: %s", err)
	}

	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		log.Fatalf("unable to initialize driver due to=%s", err)
	}

	mi, err := migrate.NewWithDatabaseInstance(
		"file://../db/migrations/", dbName, driver,
	)
	if err != nil {
		log.Fatalf("unable to initialize migrator due to=%s", err)
	}

	// runs migrations (and also our seed)
	err = mi.Up()

	if err != nil && err != migrate.ErrNoChange {
		log.Fatalf("unable to run migrations due to=%s", err)
	}

	// our test runs here
	code := m.Run()

	// we purge container
	if err = pool.Purge(resource); err != nil {
		log.Fatalf("Could not purge resource: %s", err)
	}

	os.Exit(code)
}

func TestPeopleRepository_FindAll(t *testing.T) {
	var res time.Time
	err := db.QueryRow("SELECT now();").Scan(&res)
	assert.Nil(t, err, "we got error at query current time")

	log.Println("Hello!")
	log.Println(res.Format(time.RFC3339))
}
```

TestMain runs as testing.M. Our TestPeopleRepository_FindAll test will run at `code := m.Run()` line. Main test a wrapper for our other tests.

If we run tests we will see output like below:

```
=== RUN   TestPeopleRepository_FindAll
2021/09/18 18:25:46 Hello!
2021/09/18 18:25:46 2021-09-18T15:25:46Z
--- PASS: TestPeopleRepository_FindAll (0.01s)
PASS
```

We have confirmed that we can run integration tests and query postgres shall we proceed to writing real tests?

Let's go:

```go
func TestPeopleRepository_FindAll(t *testing.T) {
	repo := PeopleRepository{Database: db}

	people, err := repo.FindAll()

	require.Nil(t, err, "unexpected to get an error at this step")
	assert.Equal(t, 4, len(people))

	var names []string

	for _, person := range people {
		names = append(names, person.FullName)
	}

	assert.Equal(t, []string{"John Doe", "Aida Bugg", "Maureen Biologist", "Allie Grater"}, names)
}
```

Okay. I admit it's really bad test bad you get the idea right? If we run this test we'll see go complains something:

```
# github.com/yigitsadic/listele/database [github.com/yigitsadic/listele/database.test]
database/people_test.go:86:10: undefined: PeopleRepository
FAIL    github.com/yigitsadic/listele/database [build failed]
FAIL
```

Let's implement `PeopleRepository` struct to pass tests. I will create `people.go` under `database` package.

```go
package database

import "database/sql"

// PeopleRepository is a struct to interact with database.
type PeopleRepository struct {
	Database *sql.DB
}

// FindAll satisfies interface. Fetches all records in people table.
func (p *PeopleRepository) FindAll() ([]Person, error) {
	rows, err := p.Database.Query("SELECT fullname FROM people")
	if err != nil {
		return nil, err
	}

	var people []Person

	for rows.Next() {
		var person Person

		if err = rows.Scan(&person.FullName); err == nil {
			people = append(people, person)
		}
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return people, err
}
```

As you can see, it fetches all records' full name fields and returns slice of Person structs.

Let's run tests again:

```
ok      github.com/yigitsadic/listele/database        4.890s
```

They're passing! But what cost? 4 seconds are really long time. Let's do something for preventing running these tests unless we explicitly told so.
Let's add this line to very beginning of `TestMain` function.

```go
func TestMain(m *testing.M) {
	// Only run if RUN_INTEGRATION_TESTS is YES
	if os.Getenv("RUN_INTEGRATION_TESTS") != "YES" {
		os.Exit(0)
	}

  /*
  Rest of code...
  */
}
```

If we run our tests with `RUN_INTEGRATION_TESTS` environment variable with content `YES` we'll run integration tests unless we'll pass them.

Verify with `go test ./database`:

```
ok      github.com/yigitsadic/listele/database        0.149s
```

Before we continue to proceed let's run all tests with `RUN_INTEGRATION_TESTS=YES go test ./...`

```
?       github.com/yigitsadic/listele [no test files]
ok      github.com/yigitsadic/listele/database        4.799s
ok      github.com/yigitsadic/listele/handlers        0.476s
```

# Connecting all together

Let's edit our lovely `main.go` file.

```go
package main

import (
	"database/sql"
	"github.com/gofiber/fiber/v2"
	"github.com/golang-migrate/migrate/v4"
	"github.com/yigitsadic/listele/database"
	"github.com/yigitsadic/listele/handlers"
	"log"
	"os"

	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
)

func main() {
	dataSource := os.Getenv("DATASOURCE")
	if dataSource == "" {
		dataSource = "postgres://listele_user:lorems@database:5432/listele_project?sslmode=disable"
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "3035"
	}

	db, err := sql.Open("postgres", dataSource)
	if err != nil {
		log.Fatalf("unable to open connection due to=%q", err)
	}

	if err = db.Ping(); err != nil {
		log.Fatal("unable to ping database, err=", err)
	}

	m, err := migrate.New("file://db/migrations", dataSource)
	if err != nil {
		log.Fatal("unable to run migrations due to ", err)
	}

	err = m.Up()

	if err != nil && err != migrate.ErrNoChange {
		log.Fatal("error occurred during execution of migrations ", err)
	}

	repo := database.PeopleRepository{Database: db}

	app := fiber.New()

	app.Get("/", handlers.HandleList(&repo))

	log.Fatalln(app.Listen(":" + port))
}
```

Line by line:

We connect to database, run migrations if any, initializing repository struct and mounting handler to fiber app and serve at given port.

For try we need a database. Let's dockerize!


# Docker compose

We need a dockerfile to dockerize our app. I will create a dockerfile called `Dockerfile`

```dockerfile
FROM golang:1.17.0-alpine3.13 as compiler

WORKDIR /src/app

COPY go.mod go.sum ./

COPY . .

RUN go build -o app

FROM alpine:3.13

WORKDIR /src

ARG PORT="3035"
ENV PORT=$PORT
EXPOSE $PORT

COPY --from=compiler /src/app/db /src/db
COPY --from=compiler /src/app/app /src/app
CMD ["/src/app"]
```

It's really simple in terms of dockerfiles. We have two stages. First we compile our code in golang-alpine image. And in second stage we copy our migrations and binary and run binary in alpine image.

> It's optional for experimenting but you should consider including a dockerignore file in your real projects.

For postgres I will use docker-compose. Let's create `docker-compose.yml`:

```yml
version: "3.3"

services:
  database:
    image: postgres:alpine3.14
    volumes:
      - data:/var/lib/postgresql/data
    environment:
      - "POSTGRES_PASSWORD=lorems"
      - "POSTGRES_USER=listele_user"
      - "POSTGRES_DB=listele_project"
  app:
    build:
      dockerfile: Dockerfile
      context: .
    restart: on-failure
    environment:
      - "DATASOURCE=postgres://listele_user:lorems@database:5432/listele_project?sslmode=disable"
    ports:
      - "3035:3035"
volumes:
  data:
```

As you can see in `app` section we'll restart container if we encounter with error at line `restart: on-failure`.

Let's find out is it working with `docker-compose up`

And voilà ! It's alive!

```
app_1       | 
app_1       |  ┌───────────────────────────────────────────────────┐ 
app_1       |  │                   Fiber v2.18.0                   │ 
app_1       |  │               http://127.0.0.1:3035               │ 
app_1       |  │       (bound on host 0.0.0.0 and port 3035)       │ 
app_1       |  │                                                   │ 
app_1       |  │ Handlers ............. 2  Processes ........... 1 │ 
app_1       |  │ Prefork ....... Disabled  PID ................. 1 │ 
app_1       |  └───────────────────────────────────────────────────┘ 
app_1       | 
```

Let's `curl http://localhost:3035 | jq`

```json
[
  {
    "full_name": "John Doe"
  },
  {
    "full_name": "Aida Bugg"
  },
  {
    "full_name": "Maureen Biologist"
  },
  {
    "full_name": "Allie Grater"
  }
]
```

Everything seems to be OK.

Until next time!
