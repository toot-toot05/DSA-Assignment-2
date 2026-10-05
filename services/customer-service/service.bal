public function isValidCustomerProfile(Customer customer) returns boolean {
    return customer.firstName.trim().length() > 0 &&
        customer.lastName.trim().length() > 0 &&
        customer.email.trim().length() > 0 &&
        customer.phone.trim().length() > 0;
}

public function updateCustomerProfile(Customer currentCustomer, UpdateCustomerRequest updates) returns Customer {
    string? firstName = updates.firstName;
    if firstName is string {
        currentCustomer.firstName = firstName;
    }

    string? lastName = updates.lastName;
    if lastName is string {
        currentCustomer.lastName = lastName;
    }

    string? email = updates.email;
    if email is string {
        currentCustomer.email = email;
    }

    string? phone = updates.phone;
    if phone is string {
        currentCustomer.phone = phone;
    }

    Address? address = updates.address;
    if address is Address {
        currentCustomer.address = address;
    }

    int? loyaltyPoints = updates.loyaltyPoints;
    if loyaltyPoints is int {
        currentCustomer.loyaltyPoints = loyaltyPoints;
    }

    return currentCustomer;
}
