class FornecedorModel {
  String? id;
  String nome;
  String cnpj;
  String telefone;
  String email;
  String imageUrl;

  FornecedorModel({
    this.id,
    required this.nome,
    required this.cnpj,
    required this.telefone,
    required this.email,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cnpj': cnpj,
      'telefone': telefone,
      'email': email,
      'imageUrl': imageUrl,
    };
  }

  factory FornecedorModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FornecedorModel(
      id: documentId,
      nome: map['nome'] ?? '',
      cnpj: map['cnpj'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}