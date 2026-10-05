import ballerina/time;

configurable int utcOffsetHours = 2;   // Namibia = UTC+2

function toMinutes(string hhmm) returns int|error {
    string[] parts = re `:`.split(hhmm);
    int h = check int:fromString(parts[0]);
    int m = check int:fromString(parts[1]);
    return h * 60 + m;
}

function isOpen(Restaurant r) returns boolean|error {
    time:Utc local = time:utcAddSeconds(time:utcNow(), <decimal>(utcOffsetHours * 3600));
    time:Civil c = time:utcToCivil(local);
    int now = c.hour * 60 + c.minute;
    int opens = check toMinutes(r.openTime);
    int closes = check toMinutes(r.closeTime);
    return now >= opens && now < closes;
}

// Returns () on success, a reason string if rejected, or an error if something broke
function tryReserve(string orderId, OrderPayload p) returns string|error? {
    Restaurant? found = check getRestaurant(p.restaurantId);
    if found is () {
        return "Restaurant not found";
    }
    Restaurant r = found;

    boolean open = check isOpen(r);
    if !open {
        return "Restaurant is closed";
    }

    // check everything first
    foreach OrderItem item in p.items {
        MenuItem? match = ();
        foreach MenuItem m in r.menu {
            if m.itemId == item.itemId {
                match = m;
            }
        }
        if match is () {
            return "Item not on menu: " + item.itemId;
        }
        if match.stock < item.quantity {
            return "Out of stock: " + match.name;
        }
    }

    // then take the stock
    foreach OrderItem item in p.items {
        foreach int i in 0 ..< r.menu.length() {
            if r.menu[i].itemId == item.itemId {
                r.menu[i].stock -= item.quantity;
            }
        }
    }
    check updateRestaurant(r);

    ReservedItem[] reserved = from OrderItem i in p.items
        select {itemId: i.itemId, quantity: i.quantity};
    check saveReservation({
        orderId: orderId,
        restaurantId: p.restaurantId,
        items: reserved,
        released: false
    });
    return ();
}

// Compensation: put the stock back when an order is cancelled
function releaseStock(string orderId) returns error? {
    Reservation? res = check getReservation(orderId);
    if res is () || res.released {
        return;   // nothing was reserved, or already released
    }
    Restaurant? found = check getRestaurant(res.restaurantId);
    if found is () {
        return;
    }
    Restaurant r = found;
    foreach ReservedItem item in res.items {
        foreach int i in 0 ..< r.menu.length() {
            if r.menu[i].itemId == item.itemId {
                r.menu[i].stock += item.quantity;
            }
        }
    }
    check updateRestaurant(r);
    res.released = true;
    check updateReservation(res);
}