public type Address record {|
    string street;
    string city;
    string state?;
    string country;
    string postalCode?;
|};

public type Customer record {|
    string id;
    string firstName;
    string lastName;
    string email;
    string phone;
    Address address;
    int loyaltyPoints;
    string createdAt;
    string updatedAt;
|};

public type CreateCustomerRequest record {|
    string firstName;
    string lastName;
    string email;
    string phone;
    Address address;
|};

public type UpdateCustomerRequest record {|
    string firstName?;
    string lastName?;
    string email?;
    string phone?;
    Address address?;
    int loyaltyPoints?;
|};
