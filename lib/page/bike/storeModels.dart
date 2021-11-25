import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hibaike_app/model/model.dart';

List<Model> parseModelSpec(String companyJson) {
  final parsed = json.decode(companyJson).cast<Map<String, dynamic>>();
  return parsed.map<Model>((json) => Model.fromJson(json)).toList();
}

class StoreModels{
  Future<List<Model>> loadJson() async {
  print('load bike model json load');
  String jsonString = await rootBundle.loadString('asset/modelspec-1.json');
  print(jsonString);

  return compute(parseModelSpec, jsonString);
  }
}