import ballerinax/mongodb;

configurable string mongoHost = "localhost";
configurable int mongoPort = 27017;

final mongodb:Client mongoClient = check new ({
    connection: {serverAddress: {host: mongoHost, port: mongoPort}}
});

function customers() returns mongodb:Collection|error {
    mongodb:Database db = check mongoClient->getDatabase("customers_db");
    return db->getCollection("customers");
}

public function saveCustomer(Customer newCustomer) returns Customer|error {
    mongodb:Collection col = check customers();
    check col->insertOne(newCustomer);
    return newCustomer;
}

public function getCustomer(string customerId) returns Customer|error? {
    mongodb:Collection col = check customers();
    return check col->findOne({id: customerId}, {}, {_id: 0}, Customer);
}

public function updateCustomer(Customer updatedCustomer) returns Customer|error {
    mongodb:Collection col = check customers();
    _ = check col->updateOne({id: updatedCustomer.id}, {set: updatedCustomer});
    return updatedCustomer;
}
