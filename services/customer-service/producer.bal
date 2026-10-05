import ballerinax/kafka;
import ballerina/time;
import ballerina/uuid;

configurable string kafkaHost = "localhost:9092";

final kafka:Producer producer = check new (kafkaHost, {
    clientId: "customer-service",
    acks: "all",
    retryCount: 3
});

public function publish(string topic, string customerId, string eventType, json payload) returns error? {
    json event = {
        eventId: uuid:createType1AsString(),
        eventType: eventType,
        customerId: customerId,
        timestamp: time:utcToString(time:utcNow()),
        payload: payload
    };
    check producer->send({
        topic: topic,
        key: customerId.toBytes(),
        value: event.toJsonString().toBytes()
    });
}
