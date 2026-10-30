# Strapi 4 — staging/production image (Node 20 per .nvmrc)
FROM node:20-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .

ENV NODE_ENV=staging
RUN yarn build

EXPOSE 1337

CMD ["yarn", "start"]
