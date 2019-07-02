# Spock example

## Running

```sh
docker-compose up # starts a database

# in other terminal window
yarn               # installs deps (just once)
yarn migrate       # migrate database schema
yarn start-etl     # starts ETL
yarn start-api     # starts GraphQL API
```