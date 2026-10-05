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
final mongodb:Collection orders = check collection("orders");
final kafka:Producer orderProducer = check new (kafkaUrl);

function collection(string name) returns mongodb:Collection|error {
    mongodb:Database db = check mongo->getDatabase("fooddelivery");
    return db->getCollection(name);
}

type Item record {|
    string name;
    int qty;
    decimal price;
|};

type Order record {
    string id;
    string customerId;
    string restaurantId;
    Item[] items;
    decimal total;
    string status;
};

type NewOrder record {
    string customerId;
    string restaurantId;
    Item[] items;
};

type StatusEvent record {
    string orderId;
};

service /orders on new http:Listener(9093) {

    resource function post .(NewOrder input) returns Order|error {
        decimal total = 0d;
        foreach Item item in input.items {
            total = total + (item.price * <decimal>item.qty);
        }

        Order 'order = {
            id: uuid:createType1AsString(),
            customerId: input.customerId,
            restaurantId: input.restaurantId,
            items: input.items,
            total,
            status: "CREATED"
        };
        check orders->insertOne('order);
        check orderProducer->send({topic: "orders.created", value: 'order.toJsonString().toBytes()});
        io:println(string `[ORDER] Created ${'order.id} | status=CREATED | total=${total}`);
        io:println(string `[ORDER] Published -> orders.created`);
        return 'order;
    }

    resource function get .() returns Order[]|error {
        stream<Order, error?> result = check orders->find();
        return from Order o in result
            select o;
    }

    resource function get [string id]() returns Order|http:NotFound|error {
        Order? 'order = check orders->findOne({id});
        if 'order is () {
            return http:NOT_FOUND;
        }
        return 'order;
    }

    resource function put [string id]/status(@http:Payload record {|string status;|} body)
            returns Order|http:NotFound|error {
        mongodb:UpdateResult result = check orders->updateOne({id}, {set: {status: body.status}});
        if result.matchedCount == 0 {
            return http:NOT_FOUND;
        }
        io:println(string `[ORDER] ${id} status set to ${body.status}`);
        Order? 'order = check orders->findOne({id});
        return 'order ?: http:NOT_FOUND;
    }
}

listener kafka:Listener orderEvents = new (kafkaUrl, {
    groupId: "order-service",
    topics: ["payments.completed", "delivery.assigned", "delivery.completed"],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
});

service on orderEvents {
    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord rec in records {
            string message = check string:fromBytes(rec.value);
            string topic = rec.offset.partition.topic;
            StatusEvent event = check (check message.fromJsonString()).cloneWithType();
            string status = topic == "payments.completed" ? "CONFIRMED"
                : topic == "delivery.assigned" ? "OUT_FOR_DELIVERY"
                : "DELIVERED";
            _ = check orders->updateOne({id: event.orderId}, {set: {status}});
            io:println(string `[ORDER] Received <- ${topic}`);
            io:println(string `[ORDER] ${event.orderId} -> ${status}`);
        }
    }
}
