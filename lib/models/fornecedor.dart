class Fornecedor {
  final int id;
  final String nome;
  final String cpfCnpj;
  final String? telefone;
  final String? email;
  final String? endereco;
  final DateTime dataCadastro;

  Fornecedor({
    required this.id,
    required this.nome,
    required this.cpfCnpj,
    this.telefone,
    this.email,
    this.endereco,
    required this.dataCadastro,
  });

  factory Fornecedor.fromJson(Map<String, dynamic> json) {
    return Fornecedor(
      id: json['id'],
      nome: json['nome'],
      cpfCnpj: json['cpf_cnpj'],
      telefone: json['telefone'],
      email: json['email'],
      endereco: json['endereco'],
      dataCadastro: DateTime.parse(json['data_cadastro']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome_completo': nome,
      'cpf_cnpj': cpfCnpj,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
    };
  }
}
