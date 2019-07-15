#!/usr/bin/env bash

docker-compose down && docker-compose up &
sleep 12s
yarn migrate
yarn start-api