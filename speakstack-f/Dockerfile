# Flutter web image for Hetzner staging (optional --profile web).
# Requires assets/mathe_config.txt before build (see deploy/mathe_config.staging.example).
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
COPY . .

RUN flutter pub get \
  && flutter build web --release --base-href /web/ --pwa-strategy none

FROM nginx:1.27-alpine

COPY deploy/nginx-web.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html/web

EXPOSE 80
