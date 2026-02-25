/// Model para Cliente do módulo financeiro
class Cliente {
  final String? id;
  final String nome;
  final String cpfCnpj;
  final String? telefone;
  final String? endereco;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cliente({
    this.id,
    required this.nome,
    required this.cpfCnpj,
    this.telefone,
    this.endereco,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nome: json['nome'],
      cpfCnpj: json['cpf_cnpj'],
      telefone: json['telefone'],
      endereco: json['endereco'],
      email: json['email'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cpf_cnpj': cpfCnpj,
      'telefone': telefone,
      'endereco': endereco,
      'email': email,
    };
  }

  Cliente copyWith({
    String? id,
    String? nome,
    String? cpfCnpj,
    String? telefone,
    String? endereco,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cliente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cpfCnpj: cpfCnpj ?? this.cpfCnpj,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
