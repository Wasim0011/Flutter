import 'package:freezed_annotation/freezed_annotation.dart';

part 'certificate.freezed.dart';
part 'certificate.g.dart';

@freezed
class Certificate with _$Certificate {
  const factory Certificate({
    required String banner,
    required String icon,
    required String title,
    required String description,
    required String link,
  }) = _Certificate;

  factory Certificate.fromJson(Map<String, Object?> json) =>
      _$CertificateFromJson(json);
}
