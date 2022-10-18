FROM node:12

EXPOSE 3001

WORKDIR /app
COPY . /app

RUN yarn

RUN yarn migrate

# RUN yarn start-etl
CMD ["yarn", "start-api"]

ENV NODE_ENV=production
