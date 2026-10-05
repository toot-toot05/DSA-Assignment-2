public type MenuItem record {|
    string itemId;
    string name;
    decimal price;
    int stock;
|};

public type Restaurant record {|
    string id;
    string name;
    string openTime;   // "08:00"
    string closeTime;  // "22:00"
    MenuItem[] menu;
|};

public type CreateRestaurantRequest record {|
    string name;
    string openTime;
    string closeTime;
    MenuItem[] menu;
|};

public type StockUpdate record {|
    int stock;
|};

public type ReservedItem record {|
    string itemId;
    int quantity;
|};

public type Reservation record {|
    string orderId;
    string restaurantId;
    ReservedItem[] items;
    boolean released;
|};

// What we read from the order event (extra fields are ignored)
public type OrderItem record {
    string itemId;
    int quantity;
};

public type OrderPayload record {
    string restaurantId;
    string customerId;
    decimal totalAmount;
    OrderItem[] items;
};

public type OrderEvent record {|
    string eventId;
    string eventType;
    string orderId;
    string timestamp;
    json payload;
|};