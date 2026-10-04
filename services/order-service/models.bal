public type OrderStatus
    "CREATED"
    | "CONFIRMED"
    | "PREPARING"
    | "READY"
    | "OUT_FOR_DELIVERY"
    | "DELIVERED"
    | "CANCELLED";

public type Order record {|
    string id;
    string customerId;
    string restaurantId;
    string? driverId;
    decimal totalAmount;
    OrderStatus status;
|};

public type StatusUpdateRequest record {|
    OrderStatus status;
|};