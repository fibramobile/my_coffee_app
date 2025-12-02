class Address {
  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final String cep;

  Address({
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      number: json['number'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      cep: json['cep'] ?? '',
    );
  }
}

class Client {
  final String id;
  final String name;
  final String cpf;
  final String phone;
  final String email;
  final Address address;
  final DateTime? createdAt;

  Client({
    required this.id,
    required this.name,
    required this.cpf,
    required this.phone,
    required this.email,
    required this.address,
    required this.createdAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      cpf: json['cpf'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: Address.fromJson(json['address'] ?? const {}),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}
