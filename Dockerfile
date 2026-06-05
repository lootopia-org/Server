FROM haskell:9.6 AS builder

RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    pkg-config \
    zlib1g-dev \
    libgmp-dev \
    build-essential

RUN echo "deb http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgres.gpg && \
    apt-get update && \
    apt-get install -y \
      libpq-dev \
      postgresql-client-16

WORKDIR /src
COPY . .

RUN cabal update
RUN cabal build exe:server exe:migrate

RUN cp dist-newstyle/build/*/ghc-*/server-*/x/server/build/server/server /tmp/server
RUN cp dist-newstyle/build/*/ghc-*/server-*/x/migrate/build/migrate/migrate /tmp/migrate


FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libgmp10 \
    libpq5 \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /tmp/server /app/server
COPY --from=builder /tmp/migrate /app/migrate

RUN chmod +x /app/server /app/migrate

ENTRYPOINT ["/bin/sh", "-c", "/app/migrate && exec /app/server"]
