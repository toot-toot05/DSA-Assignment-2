import ballerina/http;
import ballerina/uuid;

configurable int port = 9002;

listener http:Listener httpListener = new (port);

service /health on httpListener {
    resource function get .() returns string {
        return "OK";
    }
}

service /restaurants on httpListener {

    resource function post .(@http:Payload CreateRestaurantRequest req) returns Restaurant|error {
        Restaurant r = {
            id: uuid:createType1AsString(),
            name: req.name,
            openTime: req.openTime,
            closeTime: req.closeTime,
            menu: req.menu
        };
        return saveRestaurant(r);
    }

    resource function get .() returns Restaurant[]|error {
        return getAllRestaurants();
    }

    resource function get [string id]() returns Restaurant|http:NotFound|error {
        Restaurant? r = check getRestaurant(id);
        if r is () {
            return http:NOT_FOUND;
        }
        return r;
    }

    resource function put [string id]/menu/[string itemId]/stock(@http:Payload StockUpdate req)
            returns Restaurant|http:NotFound|error {
        Restaurant? found = check getRestaurant(id);
        if found is () {
            return http:NOT_FOUND;
        }
        Restaurant r = found;
        boolean changed = false;
        foreach int i in 0 ..< r.menu.length() {
            if r.menu[i].itemId == itemId {
                r.menu[i].stock = req.stock;
                changed = true;
            }
        }
        if !changed {
            return http:NOT_FOUND;
        }
        check updateRestaurant(r);
        return r;
    }
}