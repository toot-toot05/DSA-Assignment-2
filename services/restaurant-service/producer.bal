import ballerinax/kafka;
import ballerina/uuid;
import ballerina/time;

configurable string kafkaHost = "localhost:9092";

final kafka:Producer producer = check new (kafkaHost, {
    clientId: "restaurant-service",
    acks: "all",
    retryCount: 3
});

public function publish(string topic, string orderId, string eventType, json payload) returns error? {
    json event = {
        eventId: uuid:createType1AsString(),
        eventType: eventType,
        orderId: orderId,
        timestamp: time:utcToString(time:utcNow()),
        payload: payload
    };
    check producer->send({
        topic: topic,
        key: orderId.toBytes(),
        value: event.toJsonString().toBytes()
    });
}