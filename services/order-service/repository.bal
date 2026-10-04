map<Order> orderRegistry = {};

public function saveOrder(Order newOrder) returns Order {
    orderRegistry[newOrder.id] = newOrder;
    return newOrder;
}

public function getOrder(string orderId) returns Order? {
    return orderRegistry[orderId];
}

public function updateOrder(Order updatedOrder) returns Order {
    orderRegistry[updatedOrder.id] = updatedOrder;
    return updatedOrder;
}