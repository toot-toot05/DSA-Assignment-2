public function isValidTransition(OrderStatus current, OrderStatus next) returns boolean {
    match current {
        "CREATED" => {
            return next == "CONFIRMED" || next == "CANCELLED";
        }
        "CONFIRMED" => {
            return next == "PREPARING" || next == "CANCELLED";
        }
        "PREPARING" => {
            return next == "READY";
        }
        "READY" => {
            return next == "OUT_FOR_DELIVERY";
        }
        "OUT_FOR_DELIVERY" => {
            return next == "DELIVERED";
        }
        "DELIVERED" => {
            return false;
        }
        "CANCELLED" => {
            return false;
        }
    }

    return false;
}

public function transitionOrder(Order currentOrder, OrderStatus nextStatus) returns Order|error {
    if !isValidTransition(currentOrder.status, nextStatus) {
        return error("Invalid order status transition: " + currentOrder.status + " -> " + nextStatus);
    }

    currentOrder.status = nextStatus;

    return currentOrder;
}