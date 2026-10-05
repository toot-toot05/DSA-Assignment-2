import ballerina/http;
import ballerina/io;
import ballerina/os;
import ballerina/uuid;
import ballerinax/kafka;
import ballerinax/mongodb;

function env(string name, string fallback) returns string {
    string value = os:getEnv(name);
    return value == "" ? fallback : value;
}

final string mongoUrl = env("MONGO_URL", "mongodb://localhost:27017");
final string kafkaUrl = env("KAFKA_URL", "localhost:9092");

final mongodb:Client mongo = check new ({connection: mongoUrl});
final mongodb:Collection deliveries = check collection("deliveries");
final kafka:Producer deliveryProducer = check new (kafkaUrl);
final readonly & string[] drivers = ["Alice", "Bob", "Charlie", "Diana"];

function collection(string name) returns mongodb:Collection|error {
    mongodb:Database db = check mongo->getDatabase("fooddelivery");
    return db->getCollection(name);
}

type Delivery record {|
    string id;
    string orderId;
    string driver;
    string status;
|};

type PaymentEvent record {
    string orderId;
};

service /deliveries on new http:Listener(9095) {

    resource function get .() returns Delivery[]|error {
        stream<Delivery, error?> result = check deliveries->find();
        return from Delivery d in result
            select d;
    }

    resource function put [string orderId]/complete() returns Delivery|http:NotFound|error {
        mongodb:UpdateResult result = check deliveries->updateOne({orderId}, {set: {status: "DELIVERED"}});
        if result.matchedCount == 0 {
            return http:NOT_FOUND;
        }
        json completed = {orderId};
        check deliveryProducer->send({topic: "delivery.completed", value: completed.toJsonString().toBytes()});
        io:println(string `[DELIVERY] Order ${orderId} marked DELIVERED`);
        io:println(string `[DELIVERY] Published -> delivery.completed`);
        Delivery? delivery = check deliveries->findOne({orderId});
        return delivery ?: http:NOT_FOUND;
    }
}

listener kafka:Listener paymentsCompleted = new (kafkaUrl, {
    groupId: "delivery-service",
    topics: ["payments.completed"],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
});

service on paymentsCompleted {
    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord rec in records {
            string message = check string:fromBytes(rec.value);
            PaymentEvent event = check (check message.fromJsonString()).cloneWithType();

            int count = check deliveries->countDocuments();
            string driver = drivers[count % drivers.length()];
            Delivery delivery = {
                id: uuid:createType1AsString(),
                orderId: event.orderId,
                driver,
                status: "ASSIGNED"
            };
            check deliveries->insertOne(delivery);

            json assigned = {orderId: event.orderId, driver};
            check deliveryProducer->send({topic: "delivery.assigned", value: assigned.toJsonString().toBytes()});
            io:println(string `[DELIVERY] Received <- payments.completed`);
            io:println(string `[DELIVERY] Driver ${driver} assigned to order ${event.orderId}`);
            io:println(string `[DELIVERY] Published -> delivery.assigned`);
        }
    }
}
