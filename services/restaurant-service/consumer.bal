import ballerinax/kafka;
import ballerina/log;

listener kafka:Listener restaurantListener = new (kafkaHost, {
    groupId: "restaurant-service",
    topics: ["orders.created", "orders.cancelled"]
});

service on restaurantListener {

    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord rec in records {
            string text = check string:fromBytes(rec.value);
            json raw = check text.fromJsonString();
            OrderEvent event = check raw.cloneWithType();
            error? result = handleEvent(event);
            if result is error {
                log:printError("Failed to handle event", result);
            }
        }
    }
}

function handleEvent(OrderEvent event) returns error? {
    match event.eventType {
        "ORDER_CREATED" => {
            // duplicate message? already reserved, skip
            Reservation? existing = check getReservation(event.orderId);
            if existing is Reservation {
                return;
            }
            OrderPayload p = check event.payload.cloneWithType();
            string|error? outcome = tryReserve(event.orderId, p);
            if outcome is error {
                return outcome;
            }
            if outcome is string {
                check publish("inventory.rejected", event.orderId, "INVENTORY_REJECTED",
                    {reason: outcome});
            } else {
                check publish("inventory.reserved", event.orderId, "INVENTORY_RESERVED",
                    {amount: p.totalAmount, customerId: p.customerId, restaurantId: p.restaurantId});
            }
        }
        "ORDER_CANCELLED" => {
            check releaseStock(event.orderId);
        }
    }
}