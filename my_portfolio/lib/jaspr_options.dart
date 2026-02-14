// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/jaspr.dart';
import 'package:my_portfolio/components/app_button.dart' as prefix0;
import 'package:my_portfolio/components/certificate_card.dart' as prefix1;
import 'package:my_portfolio/components/contact.dart' as prefix2;
import 'package:my_portfolio/components/footer.dart' as prefix3;
import 'package:my_portfolio/components/nav_bar.dart' as prefix4;
import 'package:my_portfolio/components/project_card.dart' as prefix5;
import 'package:my_portfolio/components/service_card.dart' as prefix6;
import 'package:my_portfolio/pages/home.dart' as prefix7;
import 'package:my_portfolio/sections/about_me.dart' as prefix8;
import 'package:my_portfolio/sections/basic_info.dart' as prefix9;
import 'package:my_portfolio/sections/certificates.dart' as prefix10;
import 'package:my_portfolio/sections/contact.dart' as prefix11;
import 'package:my_portfolio/sections/projects.dart' as prefix12;
import 'package:my_portfolio/sections/services.dart' as prefix13;
import 'package:my_portfolio/app.dart' as prefix14;

/// Default [JasprOptions] for use with your jaspr project.
///
/// Use this to initialize jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'jaspr_options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultJasprOptions,
///   );
///
///   runApp(...);
/// }
/// ```
final defaultJasprOptions = JasprOptions(
  clients: {
    prefix14.App: ClientTarget<prefix14.App>('app'),
    prefix0.AppButton: ClientTarget<prefix0.AppButton>('components/app_button', params: _prefix0AppButton),
    prefix1.CertificateCard:
        ClientTarget<prefix1.CertificateCard>('components/certificate_card', params: _prefix1CertificateCard),
    prefix2.ContactCard: ClientTarget<prefix2.ContactCard>('components/contact', params: _prefix2ContactCard),
    prefix3.Footer: ClientTarget<prefix3.Footer>('components/footer'),
    prefix4.NavBar: ClientTarget<prefix4.NavBar>('components/nav_bar'),
    prefix5.ProjectCard: ClientTarget<prefix5.ProjectCard>('components/project_card', params: _prefix5ProjectCard),
    prefix6.ServiceCard: ClientTarget<prefix6.ServiceCard>('components/service_card', params: _prefix6ServiceCard),
    prefix8.AboutMeSection: ClientTarget<prefix8.AboutMeSection>('sections/about_me', params: _prefix8AboutMeSection),
  },
  styles: () => [
    ...prefix0.AppButton.styles,
    ...prefix1.CertificateCard.styles,
    ...prefix2.ContactCard.styles,
    ...prefix3.Footer.styles,
    ...prefix4.NavBar.styles,
    ...prefix5.ProjectCard.styles,
    ...prefix6.ServiceCard.styles,
    ...prefix7.Home.styles,
    ...prefix8.AboutMeSection.styles,
    ...prefix9.BasicInfoSection.styles,
    ...prefix10.CertificatesSections.styles,
    ...prefix11.ContactSection.styles,
    ...prefix12.ProjectsSections.styles,
    ...prefix13.ServicesSection.styles,
    ...prefix14.AppState.styles,
  ],
);

Map<String, dynamic> _prefix0AppButton(prefix0.AppButton c) =>
    {'label': c.label, 'href': c.href, 'width': c.width, 'height': c.height};
Map<String, dynamic> _prefix1CertificateCard(prefix1.CertificateCard c) =>
    {'title': c.title, 'description': c.description, 'icon': c.icon, 'banner': c.banner, 'url': c.url};
Map<String, dynamic> _prefix2ContactCard(prefix2.ContactCard c) =>
    {'icon': c.icon, 'title': c.title, 'description': c.description, 'action': c.action};
Map<String, dynamic> _prefix5ProjectCard(prefix5.ProjectCard c) =>
    {'title': c.title, 'description': c.description, 'icon': c.icon, 'banner': c.banner, 'url': c.url};
Map<String, dynamic> _prefix6ServiceCard(prefix6.ServiceCard c) => {'icon': c.icon, 'label': c.label};
Map<String, dynamic> _prefix8AboutMeSection(prefix8.AboutMeSection c) => {'about': c.about, 'basic': c.basic};
