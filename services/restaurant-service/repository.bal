import ballerinax/mongodb;

configurable string mongoHost = "localhost";
configurable int mongoPort = 27017;

final mongodb:Client mongoClient = check new ({
    connection: {serverAddress: {host: mongoHost, port: mongoPort}}
});

function restaurants() returns mongodb:Collection|error {
    mongodb:Database db = check mongoClient->getDatabase("restaurants_db");
    return db->getCollection("restaurants");
}

function reservations() returns mongodb:Collection|error {
    mongodb:Database db = check mongoClient->getDatabase("restaurants_db");
    return db->getCollection("reservations");
}

public function saveRestaurant(Restaurant r) returns Restaurant|error {
    mongodb:Collection col = check restaurants();
    check col->insertOne(r);
    return r;
}

public function getRestaurant(string id) returns Restaurant|error? {
    mongodb:Collection col = check restaurants();
    return check col->findOne({id: id}, {projection: {_id: 0}}, Restaurant);
}

public function getAllRestaurants() returns Restaurant[]|error {
    mongodb:Collection col = check restaurants();
    stream<Restaurant, error?> s = check col->find({}, {projection: {_id: 0}}, Restaurant);
    return check from Restaurant r in s select r;
}

public function updateRestaurant(Restaurant r) returns error? {
    mongodb:Collection col = check restaurants();
    _ = check col->updateOne({id: r.id}, {set: r});
}

public function saveReservation(Reservation r) returns error? {
    mongodb:Collection col = check reservations();
    check col->insertOne(r);
}

public function getReservation(string orderId) returns Reservation|error? {
    mongodb:Collection col = check reservations();
    return check col->findOne({orderId: orderId}, {projection: {_id: 0}}, Reservation);
}

public function updateReservation(Reservation r) returns error? {
    mongodb:Collection col = check reservations();
    _ = check col->updateOne({orderId: r.orderId}, {set: r});
}