import 'dart:convert';

List<Model> modelFromJson(String str) => List<Model>.from(json.decode(str).map((x) => Model.fromJson(x)));

String modelToJson(List<Model> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Model {
  Model({
    this.company,
    this.model,
  });

  String company;
  List<ModelElement> model;

  factory Model.fromJson(Map<String, dynamic> json) => Model(
    company: json["company"],
    model: List<ModelElement>.from(json["model"].map((x) => ModelElement.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "company": company,
    "model": List<dynamic>.from(model.map((x) => x.toJson())),
  };
}

class ModelElement {
  ModelElement({
    this.name,
    this.displacement,
    this.fuel,
    this.type,
  });

  String name;
  int displacement;
  String fuel;
  String type;

  factory ModelElement.fromJson(Map<String, dynamic> json) => ModelElement(
    name: json["name"],
    displacement: json["displacement"],
    fuel: json["fuel"],
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "displacement": displacement,
    "fuel": fuel,
    "type": type,
  };
}
