# Food Delivery Kafka Microservices

A Ballerina-based food delivery system built with Kafka and MongoDB.

## Services

| Service      | Port | Role                                      |
| ------------ | ---- | ----------------------------------------- |
| customer     | 9091 | Manage customer information and records   |
| restaurant   | 9092 | Handle restaurants and their menus        |
| order        | 9093 | Create orders and manage order statuses   |
| payment      | —    | Processes payments through `orders.created` |
| delivery     | 9095 | Allocate drivers and finalize deliveries  |
| notification | —    | Records Kafka events throughout the system |
| admin        | 9097 | Provides summaries, revenue, and delivery reports |

## Kafka flow

```text
POST /orders
  -> orders.created
  -> payment processes payment -> payments.completed
  -> order becomes CONFIRMED
  -> delivery assigns a driver -> delivery.assigned
  -> order becomes OUT_FOR_DELIVERY
PUT /deliveries/{orderId}/complete
  -> delivery.completed
  -> order becomes DELIVERED
```

## Run

```bash
docker compose up --build -d
```

Monitor the service activity with:

```bash
docker compose logs -f order payment delivery notification
```

## Ballerina CLI (local)

```bash
cd client
bal run
```

Alternatively, run a specific option directly:

```bash
bal run -- seed
bal run -- customer
bal run -- admin
```

CLI options:

1. Populate the system with example restaurants, customers, and orders
2. Access the customer portal to browse, place orders, and track deliveries
3. Open the admin dashboard for reports and delivery completion
