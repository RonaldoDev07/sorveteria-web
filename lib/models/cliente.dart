class Cliente {
  final int id;
  final String nome;
  final String cpfCnpj;
  final String? telefone;
  final String? email;
  final String? endereco;
  final double? limiteCredito;
  final DateTime dataCadastro;

  Cliente({
    required this.id,
    required this.nome,
    required this.cpfCnpj,
    this.telefone,
    this.email,
    this.endereco,
    this.limiteCredito,
    required this.dataCadastro,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nome: json['nome'],
      cpfCnpj: json['cpf_cnpj'],
      telefone: json['telefone'],
      email: json['email'],
      endereco: json['endereco'],
      limiteCredito: json['limite_credito']?.toDouble(),
      dataCadastro: DateTime.parse(json['data_cadastro']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cpf_cnpj': cpfCnpj,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      'limite_credito': limiteCredito,
    };
  }
}
