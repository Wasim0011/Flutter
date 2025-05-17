// import 'package:devfolio/components/app_button.dart';
import 'package:devfolio/models/certificate.dart';
import 'package:jaspr/jaspr.dart';
import 'package:devfolio/components/certificate_card.dart';

class CertificatesSections extends StatelessComponent {
  final List<Certificate> certificates;
  const CertificatesSections({
    super.key,
    required this.certificates,
  });

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield section(classes: 'certificates-section', [
      span(classes: 'title', [
        text('Certificates'),
      ]),
      span(classes: 'subtitle', [
        text("These are some of the certificates I've obtained :)"),
      ]),
      div(classes: 'section-body-projects', id: 'certificates', [
        for (final certificate in certificates)
          CertificateCard(
            banner: certificate.banner,
            icon: certificate.icon,
            title: certificate.title,
            description: certificate.description,
            url: certificate.link,
          ),
      ]),
      // div(styles: Styles.box(height: 45.px), []),
      // AppButton(
      //   label: 'See more',
      //   href: 'https://github.com/Wasim0011',
      // ),
    ]);
  }

  @css
  static final List<StyleRule> styles = [
    css('.certificates-section')
        .flexbox(
      direction: FlexDirection.column,
      alignItems: AlignItems.center,
      justifyContent: JustifyContent.start,
    )
        .box(
      padding: EdgeInsets.symmetric(vertical: 5.vh, horizontal: 10.vw),
    ),
    css('.section-body-certificates')
        .flexbox(
      direction: FlexDirection.row,
      alignItems: AlignItems.center,
      justifyContent: JustifyContent.center,
      wrap: FlexWrap.wrap,
    )
        .box(
      margin: EdgeInsets.only(top: 50.px),
      width: 100.percent,
    ),
  ];
}
