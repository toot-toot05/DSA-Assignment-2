import ballerina/http;
import ballerina/time;
import ballerina/uuid;

configurable int port = 9002;

listener http:Listener httpListener = new (port);

service /health on httpListener {
    resource function get .() returns string {
        return "OK";
    }
}

service /customers on httpListener {

    resource function post .(@http:Payload CreateCustomerRequest req) returns Customer|error {
        string now = time:utcToString(time:utcNow());
        Customer newCustomer = {
            id: uuid:createType1AsString(),
            firstName: req.firstName.trim(),
            lastName: req.lastName.trim(),
            email: req.email.trim(),
            phone: req.phone.trim(),
            address: req.address,
            loyaltyPoints: 0,
            createdAt: now,
            updatedAt: now
        };

        if !isValidCustomerProfile(newCustomer) {
            return error("Customer details are incomplete or invalid");
        }

        Customer saved = check saveCustomer(newCustomer);
        check publish("customers.created", saved.id, "CUSTOMER_CREATED", saved.toJson());
        return saved;
    }

    resource function get [string customerId]() returns Customer|http:NotFound|error {
        Customer? existingCustomer = check getCustomer(customerId);
        if existingCustomer is () {
            return http:NOT_FOUND;
        }
        return existingCustomer;
    }

    resource function put [string customerId](@http:Payload UpdateCustomerRequest updates)
            returns Customer|http:NotFound|http:BadRequest|error {
        Customer? existingCustomer = check getCustomer(customerId);
        if existingCustomer is () {
            return http:NOT_FOUND;
        }

        Customer updatedCustomer = updateCustomerProfile(existingCustomer, updates);
        if !isValidCustomerProfile(updatedCustomer) {
            return http:BAD_REQUEST;
        }

        updatedCustomer.updatedAt = time:utcToString(time:utcNow());
        Customer saved = check updateCustomer(updatedCustomer);
        check publish("customers.updated", saved.id, "CUSTOMER_UPDATED", saved.toJson());
        return saved;
    }
}
