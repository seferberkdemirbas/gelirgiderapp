// lib/models/category_model.dart

class CategoryModel {
  final int? id;
  final String name;

  CategoryModel({this.id, required this.name});

  Map<String, dynamic> toMap() => {if (id != null) 'id': id, 'name': name};

  factory CategoryModel.fromMap(Map<String, dynamic> m) {
    return CategoryModel(id: m['id'] as int?, name: m['name'] as String);
  }
}
