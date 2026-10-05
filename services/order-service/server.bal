import ballerina/http;
import ballerina/time;
import ballerina/uuid;

configurable int port = 9003;

listener http:Listener httpListener = new (port);

service /health on httpListener {
    resource function get .() returns string {
        return "OK";
    }
}

service /orders on httpListener {

    resource function post .(@http:Payload CreateOrderRequest req) returns Order|error {
        decimal total = 0;
        foreach OrderItem item in req.items {
            total += item.unitPrice * <decimal>item.quantity;
        }
        string now = time:utcToString(time:utcNow());
        Order newOrder = {
            id: uuid:createType1AsString(),
            customerId: req.customerId,
            restaurantId: req.restaurantId,
            items: req.items,
            deliveryAddress: req.deliveryAddress,
            totalAmount: total,
            status: "CREATED",
            statusHistory: [{status: "CREATED", at: now}],
            createdAt: now,
            updatedAt: now
        };
        Order saved = check saveOrder(newOrder);
        check publish("orders.created", saved.id, "ORDER_CREATED", saved.toJson());
        return saved;
    }

    resource function get [string orderId]() returns Order|http:NotFound|error {
        Order? existingOrder = check getOrder(orderId);
        if existingOrder is () {
            return http:NOT_FOUND;
        }
        return existingOrder;
    }

    resource function put [string orderId]/status(@http:Payload StatusUpdateRequest statusUpdate)
            returns Order|http:NotFound|http:BadRequest|error {
        Order? existingOrder = check getOrder(orderId);
        if existingOrder is () {
            return http:NOT_FOUND;
        }
        Order|error updated = transitionOrder(existingOrder, statusUpdate.status);
        if updated is error {
            return http:BAD_REQUEST;
        }
        Order saved = check updateOrder(updated);
        check publish("orders.status.changed", saved.id, "ORDER_" + saved.status, saved.toJson());
        return saved;
    }
}