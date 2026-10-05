import ballerina/http;
import ballerina/io;
import ballerina/os;
import ballerina/uuid;
import ballerinax/mongodb;

function env(string name, string fallback) returns string {
    string value = os:getEnv(name);
    return value == "" ? fallback : value;
}

final string mongoUrl = env("MONGO_URL", "mongodb://localhost:27017");
final mongodb:Client mongo = check new ({connection: mongoUrl});
final mongodb:Collection restaurants = check collection("restaurants");

function collection(string name) returns mongodb:Collection|error {
    mongodb:Database db = check mongo->getDatabase("fooddelivery");
    return db->getCollection(name);
}

type MenuItem record {|
    string name;
    decimal price;
    int stock;
|};

type Restaurant record {|
    string id;
    string name;
    string openHours;
    MenuItem[] menu;
|};

type NewRestaurant record {|
    string name;
    string openHours;
    MenuItem[] menu;
|};

service /restaurants on new http:Listener(9092) {

    resource function post .(NewRestaurant input) returns Restaurant|error {
        Restaurant restaurant = {id: uuid:createType1AsString(), ...input};
        check restaurants->insertOne(restaurant);
        io:println(string `[RESTAURANT] Created ${restaurant.name} (${restaurant.id})`);
        return restaurant;
    }

    resource function get .() returns Restaurant[]|error {
        stream<Restaurant, error?> result = check restaurants->find();
        return from Restaurant r in result
            select r;
    }

    resource function get [string id]() returns Restaurant|http:NotFound|error {
        Restaurant? restaurant = check restaurants->findOne({id});
        if restaurant is () {
            return http:NOT_FOUND;
        }
        return restaurant;
    }

    resource function get [string id]/menu() returns MenuItem[]|http:NotFound|error {
        Restaurant? restaurant = check restaurants->findOne({id});
        if restaurant is () {
            return http:NOT_FOUND;
        }
        return restaurant.menu;
    }

    resource function put [string id](NewRestaurant input) returns Restaurant|http:NotFound|error {
        mongodb:UpdateResult result = check restaurants->updateOne({id}, {set: input});
        if result.matchedCount == 0 {
            return http:NOT_FOUND;
        }
        io:println(string `[RESTAURANT] Updated ${id}`);
        return {id, ...input};
    }

    resource function delete [string id]() returns http:NoContent|http:NotFound|error {
        mongodb:DeleteResult result = check restaurants->deleteOne({id});
        if result.deletedCount == 0 {
            return http:NOT_FOUND;
        }
        io:println(string `[RESTAURANT] Deleted ${id}`);
        return http:NO_CONTENT;
    }
}
