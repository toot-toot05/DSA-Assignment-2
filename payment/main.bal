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
final mongodb:Collection payments = check collection("payments");
final kafka:Producer paymentProducer = check new (kafkaUrl);

function collection(string name) returns mongodb:Collection|error {
    mongodb:Database db = check mongo->getDatabase("fooddelivery");
    return db->getCollection(name);
}

type Payment record {|
    string id;
    string orderId;
    decimal amount;
    string status;
|};

type OrderEvent record {
    string id;
    decimal total;
};

listener kafka:Listener orderCreated = new (kafkaUrl, {
    groupId: "payment-service",
    topics: ["orders.created"],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
});

service on orderCreated {
    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord rec in records {
            string message = check string:fromBytes(rec.value);
            OrderEvent event = check (check message.fromJsonString()).cloneWithType();

            Payment payment = {
                id: uuid:createType1AsString(),
                orderId: event.id,
                amount: event.total,
                status: "PAID"
            };
            check payments->insertOne(payment);

            json completed = {orderId: event.id, amount: event.total, status: "PAID"};
            check paymentProducer->send({topic: "payments.completed", value: completed.toJsonString().toBytes()});
            io:println(string `[PAYMENT] Received <- orders.created`);
            io:println(string `[PAYMENT] Paid ${payment.amount} for order ${event.id}`);
            io:println(string `[PAYMENT] Published -> payments.completed`);
        }
    }
}
