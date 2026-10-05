import ballerina/http;
import ballerina/io;
import ballerina/lang.'int as ints;
import ballerina/lang.runtime;

final http:Client customers = check new ("http://localhost:9091");
final http:Client restaurants = check new ("http://localhost:9092");
final http:Client orders = check new ("http://localhost:9093");
final http:Client deliveries = check new ("http://localhost:9095");
final http:Client admin = check new ("http://localhost:9097");

public function main(string... args) returns error? {
    if args.length() > 0 {
        match args[0].toLowerAscii() {
            "seed" => {
                runOrWarn(seedData);
                return;
            }
            "customer"|"c" => {
                runOrWarn(customerMenu);
                return;
            }
            "admin"|"a" => {
                runOrWarn(adminMenu);
                return;
            }
        }
    }

    while true {
        io:println("\nFood Delivery CLI");
        io:println("1. Seed sample data");
        io:println("2. Customer portal");
        io:println("3. Admin dashboard");
        io:println("4. Exit");
        string choice = io:readln("Select [1-4]: ").trim();

        match choice {
            "1" => {
                runOrWarn(seedData);
            }
            "2" => {
                runOrWarn(customerMenu);
            }
            "3" => {
                runOrWarn(adminMenu);
            }
            "4" => {
                return;
            }
            _ => {
                io:println("Invalid option.");
            }
        }
    }
}

function runOrWarn(function () returns error? action) {
    error? result = action();
    if result is error {
        io:println(string `Error: ${result.message()}`);
    }
}

function getJson(http:Client clientEp, string path) returns json|error {
    http:Response resp = check clientEp->get(path);
    return check resp.getJsonPayload();
}

function postJson(http:Client clientEp, string path, json payload) returns json|error {
    http:Response resp = check clientEp->post(path, payload);
    return check resp.getJsonPayload();
}

function putJson(http:Client clientEp, string path, json? payload = ()) returns json|error {
    http:Response resp = check clientEp->put(path, payload ?: {});
    return check resp.getJsonPayload();
}

function asArray(json data) returns json[] {
    if data is json[] {
        return data;
    }
    return [];
}

function jval(json data, string key) returns json|error {
    map<json> obj = check data.ensureType();
    json? value = obj[key];
    if value is () {
        return error(string `missing key: ${key}`);
    }
    return value;
}

function jstr(json data, string key) returns string|error {
    return (check jval(data, key)).toString();
}

function readInt(string prompt) returns int? {
    string raw = io:readln(prompt).trim();
    if raw == "" {
        io:println("Please enter a number.");
        return ();
    }
    int|error value = ints:fromString(raw);
    if value is error {
        io:println("Invalid number.");
        return ();
    }
    return value;
}

function seedData() returns error? {
    io:println("\nSeeding...");

    json[] restaurantPayloads = [
    {
        "name": "Walvis Bay Kapana Shack",
        "openHours": "09:00 - 21:00",
        "menu": [
            {"name": "Kapana Beef Plate", "price": 95.00, "stock": 35},
            {"name": "Chicken & Pap", "price": 85.00, "stock": 28},
            {"name": "Vetkoek with Mince", "price": 45.00, "stock": 40}
        ]
    },
    {
        "name": "Swakop Ocean Basket",
        "openHours": "11:00 - 22:00",
        "menu": [
            {"name": "Grilled Hake Fillet", "price": 145.00, "stock": 22},
            {"name": "Calamari & Chips", "price": 110.00, "stock": 40},
            {"name": "Fish Burger", "price": 85.00, "stock": 30}
        ]
    },
    {
        "name": "On A Roll Cafe",
        "openHours": "08:00 - 20:00",
        "menu": [
            {"name": "Chicken Power Bowl", "price": 105.00, "stock": 30},
            {"name": "Avocado & Feta Toast", "price": 75.00, "stock": 45},
            {"name": "Fresh Fruit Smoothie", "price": 55.00, "stock": 50}
        ]
    }
    ];

    json[] customerPayloads = [
        {
            "name": "Esther Shigwedha",
            "email": "esther.s@example.na",
            "phone": "+264-81-555-0123",
            "addresses": ["12 Independence Avenue, Windhoek"]
        },
        {
            "name": "Prince-Lee Shigwedha",
            "email": "princelee@example.na",
            "phone": "+264-81-555-0167",
            "addresses": ["8 Sam Nujoma Drive, Swakopmund"]
        },
        {
            "name": "Ndapewa Johannes",
            "email": "ndapewaj@example.na",
            "phone": "+264-81-555-0194",
            "addresses": ["25 Main Street, Oshakati"]
        }
    ];

    json[] seededRestaurants = [];
    foreach json r in restaurantPayloads {
        json created = check postJson(restaurants, "/restaurants", r);
        seededRestaurants.push(created);
        io:println(string `Restaurant: ${check jstr(created, "name")}`);
    }

    json[] seededCustomers = [];
    foreach json c in customerPayloads {
        json created = check postJson(customers, "/customers", c);
        seededCustomers.push(created);
        io:println(string `Customer: ${check jstr(created, "name")}`);
    }

    json[] sampleOrders = [
        {
            "customerId": check jstr(seededCustomers[0], "id"),
            "restaurantId": check jstr(seededRestaurants[0], "id"),
            "items": [
                {"name": "Bunny Chow (Chicken)", "qty": 1, "price": 11.50},
                {"name": "Malva Pudding", "qty": 2, "price": 6.50}
            ]
        },
        {
            "customerId": check jstr(seededCustomers[1], "id"),
            "restaurantId": check jstr(seededRestaurants[1], "id"),
            "items": [
                {"name": "Grilled Kingklip", "qty": 1, "price": 18.00},
                {"name": "Chips & Tartar", "qty": 1, "price": 5.00}
            ]
        }
    ];

    json[] placedOrders = [];
    foreach json o in sampleOrders {
        json placed = check postJson(orders, "/orders", o);
        placedOrders.push(placed);
        io:println(string `Order: ${check jstr(placed, "id")} total=${check jstr(placed, "total")}`);
    }

    io:println("Waiting for Kafka cascade...");
    runtime:sleep(3);

    string firstId = check jstr(placedOrders[0], "id");
    json completed = check putJson(deliveries, string `/deliveries/${firstId}/complete`);
    io:println(string `Delivery completed by ${check jstr(completed, "driver")}`);

    json summary = check getJson(admin, "/admin/reports/summary");
    io:println(string `Seed done. Orders=${check jstr(summary, "totalOrders")}, Deliveries=${check jstr(summary, "totalDeliveries")}`);
}

function customerMenu() returns error? {
    while true {
        io:println("\nCustomer portal");
        io:println("1. Browse restaurants");
        io:println("2. Place an order");
        io:println("3. Track an order");
        io:println("4. Back");
        string choice = io:readln("Select [1-4]: ").trim();

        match choice {
            "1" => {
                runOrWarn(listRestaurants);
            }
            "2" => {
                runOrWarn(placeOrder);
            }
            "3" => {
                string id = io:readln("Order ID: ").trim();
                if id == "" {
                    io:println("Order ID required.");
                } else {
                    error? result = trackOrder(id);
                    if result is error {
                        io:println(string `Error: ${result.message()}`);
                    }
                }
            }
            "4" => {
                return;
            }
            _ => {
                io:println("Invalid option.");
            }
        }
    }
}

function listRestaurants() returns error? {
    json data = check getJson(restaurants, "/restaurants");
    json[] list = asArray(data);
    if list.length() == 0 {
        io:println("No restaurants. Run seed first.");
        return;
    }
    int i = 1;
    foreach json r in list {
        io:println(string `\n[${i}] ${check jstr(r, "name")} (${check jstr(r, "openHours")})`);
        json[] menu = asArray(check jval(r, "menu"));
        int j = 1;
        foreach json item in menu {
            io:println(string `  ${j}. ${check jstr(item, "name")} - $${check jstr(item, "price")}`);
            j += 1;
        }
        i += 1;
    }
}

function placeOrder() returns error? {
    json custData = check getJson(customers, "/customers");
    json[] custList = asArray(custData);
    if custList.length() == 0 {
        io:println("No customers. Run seed first.");
        return;
    }

    io:println("\nCustomers:");
    int ci = 1;
    foreach json c in custList {
        io:println(string `  [${ci}] ${check jstr(c, "name")}`);
        ci += 1;
    }
    int? cChoice = readInt("Customer #: ");
    if cChoice is () || cChoice < 1 || cChoice > custList.length() {
        io:println("Invalid customer.");
        return;
    }
    json cust = custList[cChoice - 1];

    json restData = check getJson(restaurants, "/restaurants");
    json[] restList = asArray(restData);
    if restList.length() == 0 {
        io:println("No restaurants.");
        return;
    }

    io:println("\nRestaurants:");
    int ri = 1;
    foreach json r in restList {
        io:println(string `  [${ri}] ${check jstr(r, "name")}`);
        ri += 1;
    }
    int? rChoice = readInt("Restaurant #: ");
    if rChoice is () || rChoice < 1 || rChoice > restList.length() {
        io:println("Invalid restaurant.");
        return;
    }
    json rest = restList[rChoice - 1];
    json[] menu = asArray(check jval(rest, "menu"));

    io:println(string `\nMenu for ${check jstr(rest, "name")}:`);
    int mi = 1;
    foreach json item in menu {
        io:println(string `  [${mi}] ${check jstr(item, "name")} - $${check jstr(item, "price")}`);
        mi += 1;
    }

    json[] items = [];
    while true {
        int? mChoice = readInt("\nItem # (0 when done): ");
        if mChoice is () {
            continue;
        }
        if mChoice == 0 {
            break;
        }
        if mChoice < 1 || mChoice > menu.length() {
            io:println("Invalid item.");
            continue;
        }
        int? qty = readInt("Quantity: ");
        if qty is () || qty <= 0 {
            io:println("Quantity must be > 0.");
            continue;
        }
        json selected = menu[mChoice - 1];
        items.push({
            "name": check jval(selected, "name"),
            "qty": qty,
            "price": check jval(selected, "price")
        });
        io:println(string `Added ${qty}x ${check jstr(selected, "name")}`);
    }

    if items.length() == 0 {
        io:println("No items. Cancelled.");
        return;
    }

    string confirm = io:readln("Confirm order? (y/N): ").trim().toLowerAscii();
    if confirm != "y" {
        io:println("Cancelled.");
        return;
    }

    json created = check postJson(orders, "/orders", {
        "customerId": check jval(cust, "id"),
        "restaurantId": check jval(rest, "id"),
        "items": items
    });
    io:println(string `\nOrder created: ${check jstr(created, "id")}`);
    io:println(string `Status=${check jstr(created, "status")} Total=$${check jstr(created, "total")}`);
    check trackOrder(check jstr(created, "id"));
}

function trackOrder(string orderId) returns error? {
    io:println(string `\nTracking ${orderId}...`);
    string? last = ();
    int i = 0;
    while i < 20 {
        json|error orderResult = getJson(orders, string `/orders/${orderId}`);
        if orderResult is json {
            string status = check jstr(orderResult, "status");
            if last is () || status != last {
                io:println(string `  ${status}`);
                last = status;
                if status == "DELIVERED" {
                    return;
                }
            }
        }
        runtime:sleep(1.5);
        i += 1;
    }
    io:println("Tracking timed out (order may still be in progress).");
}

function adminMenu() returns error? {
    while true {
        io:println("\nAdmin dashboard");
        io:println("1. Platform summary");
        io:println("2. Restaurant revenue report");
        io:println("3. Delivery status breakdown");
        io:println("4. Complete a delivery");
        io:println("5. Back");
        string choice = io:readln("Select [1-5]: ").trim();

        match choice {
            "1" => {
                runOrWarn(adminSummary);
            }
            "2" => {
                runOrWarn(adminRestaurants);
            }
            "3" => {
                runOrWarn(adminDeliveries);
            }
            "4" => {
                runOrWarn(completeDelivery);
            }
            "5" => {
                return;
            }
            _ => {
                io:println("Invalid option.");
            }
        }
    }
}

function adminSummary() returns error? {
    json data = check getJson(admin, "/admin/reports/summary");
    io:println(string `Total orders: ${check jstr(data, "totalOrders")}`);
    io:println(string `Total deliveries: ${check jstr(data, "totalDeliveries")}`);
}

function adminRestaurants() returns error? {
    json data = check getJson(admin, "/admin/reports/restaurants");
    io:println(string `Order counts: ${(check jval(data, "orderCounts")).toJsonString()}`);
    io:println(string `Revenue: ${(check jval(data, "revenue")).toJsonString()}`);
}

function adminDeliveries() returns error? {
    json data = check getJson(admin, "/admin/reports/deliveries");
    io:println(string `Deliveries by status: ${(check jval(data, "deliveriesByStatus")).toJsonString()}`);
}

function completeDelivery() returns error? {
    json data = check getJson(deliveries, "/deliveries");
    json[] list = asArray(data);
    json[] active = [];
    foreach json d in list {
        if check jstr(d, "status") == "ASSIGNED" {
            active.push(d);
        }
    }
    if active.length() == 0 {
        io:println("No assigned deliveries.");
        return;
    }

    io:println("\nAssigned deliveries:");
    int i = 1;
    foreach json d in active {
        io:println(string `  [${i}] Driver=${check jstr(d, "driver")} Order=${check jstr(d, "orderId")}`);
        i += 1;
    }
    int? choice = readInt("Delivery #: ");
    if choice is () || choice < 1 || choice > active.length() {
        io:println("Invalid choice.");
        return;
    }
    string orderId = check jstr(active[choice - 1], "orderId");
    json result = check putJson(deliveries, string `/deliveries/${orderId}/complete`);
    io:println(string `Completed order ${orderId} (driver=${check jstr(result, "driver")})`);
}
