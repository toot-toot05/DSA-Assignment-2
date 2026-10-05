# Food Delivery Kafka Microservices

Simple Ballerina + Kafka + MongoDB food delivery platform.

## Services

| Service      | Port | Role                                 |
| ------------ | ---- | ------------------------------------ |
| customer     | 9091 | Customer CRUD                        |
| restaurant   | 9092 | Restaurants & menus                  |
| order        | 9093 | Place orders, status updates         |
| payment      | —    | Kafka: pay on `orders.created`       |
| delivery     | 9095 | Assign drivers, complete deliveries  |
| notification | —    | Logs all Kafka lifecycle events      |
| admin        | 9097 | Summary / revenue / delivery reports |

## Kafka flow

```
POST /orders
  -> orders.created
  -> payment pays -> payments.completed
  -> order CONFIRMED
  -> delivery assigns driver -> delivery.assigned
  -> order OUT_FOR_DELIVERY
PUT /deliveries/{orderId}/complete
  -> delivery.completed
  -> order DELIVERED
```

## Run

```bash
docker compose up --build -d
```

Watch service logs:

```bash
docker compose logs -f order payment delivery notification
```

## Ballerina CLI (local)

```bash
cd client
bal run
```

Or directly:

```bash
bal run -- seed
bal run -- customer
bal run -- admin
```

CLI options:

1. Seed sample restaurants/customers/orders
2. Customer portal (browse, order, track)
3. Admin dashboard (reports + complete delivery)
