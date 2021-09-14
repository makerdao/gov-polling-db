# Blockchain ETL for Maker Governance

Backend that uses the [spock SDK](https://github.com/oasisdex/spock) to:

1. Extract: listen for events from specified contracts. Extractors are defined in the ./config.js file.
2. Transform/Load: Sanitize the event and tx info and store it in the database. See the [spock readme](https://github.com/oasisdex/spock) for requirements on writing transformers. Transformers are found in the ./transformers folder, and written in JavaScript.
3. Expose: Use SQL functions to expose this data via a GraphQL API, in a format that makes it easier to calculate polling results. These SQL functions are found in the migrations folder. Spock uses PostGraphile to automatically create the API. Any sql function written on the `api` schema becomes a graphQL query. For example, if a sql function is in the format `api.my_function`, then a graphQL query will be created called `myFunction`.

## Development

```sh

docker-compose up # starts a database (run 'docker-compose down' then 'docker-compose up' to restart)

# in other terminal window

yarn               # installs deps (just once)

yarn migrate       # migrate database schema

yarn start-etl     # starts ETL

# in other terminal window

yarn start-api     # starts GraphQL API

```

## Environment 

Create the connection details for the database by setting the following environment variables.  A default .env file is provided, which uses the following values:
```
VL_DB_DATABASE=database
VL_DB_USER=user
VL_DB_PASSWORD=password
VL_DB_HOST=localhost
VL_DB_PORT=5433
```

You'll also need to set a `VL_CHAIN_HOST` env variable that points to an ethereum node.  Alchemy is recommended, Infura is not.  See the [spock readme](https://github.com/oasisdex/spock) for more information, and also for information about the `VL_LOGGING_LEVEL` env variable.  

## Using Postico (optional)

You can use Postico to connect to your database, just input the connection details defined by the environment variables.

In postico, you can view all the tables, and the data inside them.  In the [vulcan2x.jobs](http://vulcan2x.jobs) table, you’ll see all the extractors and transformers, and the last block id that they have processed.

## Tests (WIP)

1.  start a test db instance `yarn test:db`

2.  run the tests `yarn test`
