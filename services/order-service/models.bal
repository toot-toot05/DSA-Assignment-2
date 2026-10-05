import ballerina/time;
import ballerina/uuid;

public type OrderStatus
    "CREATED" | "CONFIRMED" | "PREPARING" | "READY"
    | "OUT_FOR_DELIVERY" | "DELIVERED" | "CANCELLED";

public type OrderItem record {|
    string itemId;
    string name;
    int quantity;
    decimal unitPrice;
|};

public type Address record {|
    string street;
    string city;
    decimal lat?;
    decimal lng?;
|};

public type StatusChange record {|
    OrderStatus status;
    string at;
    string reason?;
|};

public type Order record {|
    string id;
    string customerId;
    string restaurantId;
    string driverId?;
    OrderItem[] items;
    Address deliveryAddress;
    decimal totalAmount;
    OrderStatus status;
    StatusChange[] statusHistory;
    string createdAt;
    string updatedAt;
|};

public type CreateOrderRequest record {|
    string customerId;
    string restaurantId;
    OrderItem[] items;
    Address deliveryAddress;
|};

public type StatusUpdateRequest record {|
    OrderStatus status;
    string reason?;
|};

public final readonly & map<OrderStatus[]> TRANSITIONS = {
    "CREATED": ["CONFIRMED", "CANCELLED"],
    "CONFIRMED": ["PREPARING", "CANCELLED"],
    "PREPARING": ["READY", "CANCELLED"],
    "READY": ["OUT_FOR_DELIVERY"],
    "OUT_FOR_DELIVERY": ["DELIVERED"],
    "DELIVERED": [],
    "CANCELLED": []
};

public type OrderEvent record {|
    string eventId;
    string eventType;
    string orderId;
    string timestamp;
    json payload;
|};

public function canTransition(
    OrderStatus currentStatus,
    OrderStatus nextStatus
) returns boolean {

    OrderStatus[]? allowed = TRANSITIONS[currentStatus];

    if allowed is () {
        return false;
    }

    return allowed.indexOf(nextStatus) is int;
}