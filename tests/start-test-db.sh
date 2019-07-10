#!/usr/bin/env bash

docker-compose down && docker-compose up &
sleep 10s
yarn migrate