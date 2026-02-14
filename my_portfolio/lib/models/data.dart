import 'package:my_portfolio/models/about.dart';
import 'package:my_portfolio/models/basic.dart';
import 'package:my_portfolio/models/contact.dart';
import 'package:my_portfolio/models/project.dart';
import 'package:my_portfolio/models/service_data.dart';
import 'package:my_portfolio/models/social.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:my_portfolio/models/certificate.dart';

part 'data.freezed.dart';
part 'data.g.dart';

@freezed
class Data with _$Data {
  const factory Data({
    required Basic basic,
    required List<Social> socials,
    required About about,
    required List<ServiceData> services,
    required List<Project> projects,
    required List<Certificate> certificates,
    required List<Contact> contact,
  }) = _Data;

  factory Data.fromJson(Map<String, Object?> json) => _$DataFromJson(json);
}
