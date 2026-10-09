# Build the Flutter web release, then serve it with nginx.
# API base URL is baked in at build time (Dart --dart-define):
#   docker build --build-arg API_BASE_URL=https://api.example.com/api/v1 -t saleshub-web .
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
ARG API_BASE_URL=http://localhost:8000/api/v1
RUN flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
