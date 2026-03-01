/// Model para Fornecedor do módulo financeiro
class Fornecedor {
  final String? id;
  final String nome;
  final String cnpj;
  final String? telefone;
  final String? endereco;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Fornecedor({
    this.id,
    required this.nome,
    required this.cnpj,
    this.telefone,
    this.endereco,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory Fornecedor.fromJson(Map<String, dynamic> json) {
    return Fornecedor(
      id: json['id'],
      nome: json['nome'],
      cnpj: json['cnpj'],
      telefone: json['telefone'],
      endereco: json['endereco'],
      email: json['email'],
      createdAt: (json['createdAt'] ?? json['created_at']) != null 
          ? DateTime.parse(json['createdAt'] ?? json['created_at']) 
          : null,
      updatedAt: (json['updatedAt'] ?? json['updated_at']) != null 
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cnpj': cnpj,
      'telefone': telefone,
      'endereco': endereco,
      'email': email,
    };
  }

  Fornecedor copyWith({
    String? id,
    String? nome,
    String? cnpj,
    String? telefone,
    String? endereco,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fornecedor(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cnpj: cnpj ?? this.cnpj,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
