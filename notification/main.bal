import ballerina/io;
import ballerina/os;
import ballerinax/kafka;
import ballerinax/mongodb;

function env(string name, string fallback) returns string {
    string value = os:getEnv(name);
    return value == "" ? fallback : value;
}

final string mongoUrl = env("MONGO_URL", "mongodb://localhost:27017");
final string kafkaUrl = env("KAFKA_URL", "localhost:9092");

final mongodb:Client mongo = check new ({connection: mongoUrl});
final mongodb:Collection notifications = check collection("notifications");

function collection(string name) returns mongodb:Collection|error {
    mongodb:Database db = check mongo->getDatabase("fooddelivery");
    return db->getCollection(name);
}

listener kafka:Listener allEvents = new (kafkaUrl, {
    groupId: "notification-service",
    topics: ["orders.created", "payments.completed", "delivery.assigned", "delivery.completed"],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
});

service on allEvents {
    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord rec in records {
            string message = check string:fromBytes(rec.value);
            string topic = rec.offset.partition.topic;
            record {|string topic; string message;|} note = {topic, message};
            check notifications->insertOne(note);
            io:println(string `[NOTIFICATION] ${topic} | ${message}`);
        }
    }
}
