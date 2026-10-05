import ballerinax/mongodb;

configurable string mongoHost = "localhost";
configurable int mongoPort = 27017;

final mongodb:Client mongoClient = check new ({
    connection: {serverAddress: {host: mongoHost, port: mongoPort}}
});

function orders() returns mongodb:Collection|error {
    mongodb:Database db = check mongoClient->getDatabase("orders_db");
    return db->getCollection("orders");
}

public function saveOrder(Order newOrder) returns Order|error {
    mongodb:Collection col = check orders();
    check col->insertOne(newOrder);
    return newOrder;
}

public function getOrder(string orderId) returns Order|error? {
    mongodb:Collection col = check orders();
    return check col->findOne({id: orderId}, {}, {_id: 0}, Order);
}

public function updateOrder(Order updatedOrder) returns Order|error {
    mongodb:Collection col = check orders();
    _ = check col->updateOne({id: updatedOrder.id}, {set: updatedOrder});
    return updatedOrder;
}