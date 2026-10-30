# syntax=docker/dockerfile:1

# ---- Build de la app Flutter Web ----
FROM ghcr.io/cirruslabs/flutter:stable AS web

USER root
WORKDIR /src

COPY app/pubspec.yaml app/pubspec.lock ./
RUN flutter pub get

COPY app/ ./
RUN flutter build web --release --dart-define=SAME_ORIGIN=true --base-href /

# ---- Runtime Node ----
FROM node:22-bookworm-slim AS runtime

ENV NODE_ENV=production
ENV PORT=3000
ENV DB_PATH=/data/sella.db

WORKDIR /srv

COPY backend/package.json backend/package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY backend/ ./
COPY --from=web /src/build/web ./public/app

RUN mkdir -p /data/uploads
VOLUME ["/data"]

EXPOSE 3000
CMD ["node", "src/index.js"]
