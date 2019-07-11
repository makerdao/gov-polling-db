# Spock example

## Development

```sh
docker-compose up # starts a database
docker-compose down # remove db and network 

# in other terminal window
yarn               # installs deps (just once)
yarn migrate       # migrate database schema
yarn start-etl     # starts ETL
yarn start-api     # starts GraphQL API
```

## Running Tests

1.  start a test db instance `yarn test:db`
2.  run the tests `yarn test`
