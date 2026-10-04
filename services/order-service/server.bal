import ballerina/http;

listener http:Listener httpListener = new (8080);

service /orders on httpListener {

    resource function post .(@http:Payload Order newOrder) returns Order {
        return saveOrder(newOrder);
    }

    resource function get [string orderId]() returns Order|http:NotFound {
        Order? existingOrder = getOrder(orderId);

        if existingOrder is () {
            return http:NOT_FOUND;
        }

        return existingOrder;
    }

    resource function put [string orderId]/status(
        @http:Payload StatusUpdateRequest statusUpdate
    ) returns Order|http:NotFound|error {

        Order? existingOrder = getOrder(orderId);

        if existingOrder is () {
            return http:NOT_FOUND;
        }

        Order updatedOrder = check transitionOrder(existingOrder, statusUpdate.status);

        return updateOrder(updatedOrder);
    }
}