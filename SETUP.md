# Setup

## Prerequisites

- Docker Desktop
- Ballerina 2201.13.5 (for the CLI only)

## Start services


cd assignment2
docker compose up --build -d

Wait until Kafka, MongoDB, and all services are healthy:

docker compose ps


## Seed + use the CLI

```bash
cd client
bal run -- seed
bal run -- customer
bal run -- admin
```

Or just `bal run` for the interactive menu.

## Watch Kafka cascade in Docker logs

```bash
docker compose logs -f order payment delivery notification
```

You should see messages like:

- `[ORDER] Created ... Published -> orders.created`
- `[PAYMENT] Paid ... Published -> payments.completed`
- `[DELIVERY] Driver Alice assigned ...`
- `[NOTIFICATION] orders.created | ...`
