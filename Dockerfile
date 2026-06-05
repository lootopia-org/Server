FROM haskell:9.6 AS builder

RUN apt-get update && apt-get install -y \
    pkg-config \
    zlib1g-dev \
    libgmp-dev \
    libpq-dev \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

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
