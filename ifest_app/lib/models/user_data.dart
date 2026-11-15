class UserData {
  final String name;
  final String cpf;
  final String phone;
  final String cep;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;

  UserData({
    required this.name,
    required this.cpf,
    required this.phone,
    required this.cep,
    required this.street,
    required this.number,
    this.complement = '',
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  bool get isEmpty =>
      name.trim().isEmpty ||
      cpf.trim().isEmpty ||
      phone.trim().isEmpty ||
      street.trim().isEmpty ||
      number.trim().isEmpty ||
      city.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  String get formattedAddress {
    final comp = complement.isNotEmpty ? ' - $complement' : '';
    return '$street, $number$comp, $neighborhood, $city - $state, CEP $cep';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'cpf': cpf.trim(),
      'phone': phone.trim(),
      'cep': cep.trim(),
      'street': street.trim(),
      'number': number.trim(),
      'complement': complement.trim(),
      'neighborhood': neighborhood.trim(),
      'city': city.trim(),
      'state': state.trim(),
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      name: map['name'] as String? ?? '',
      cpf: map['cpf'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      cep: map['cep'] as String? ?? '',
      street: map['street'] as String? ?? '',
      number: map['number'] as String? ?? '',
      complement: map['complement'] as String? ?? '',
      neighborhood: map['neighborhood'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
    );
  }

  factory UserData.empty() {
    return UserData(
      name: '',
      cpf: '',
      phone: '',
      cep: '',
      street: '',
      number: '',
      complement: '',
      neighborhood: '',
      city: '',
      state: '',
    );
  }
}
