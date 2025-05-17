import 'package:devfolio/constants/theme.dart';
import 'package:jaspr/jaspr.dart';

@client
class ProjectCard extends StatelessComponent {
  final String title;
  final String description;
  final String icon;
  final String banner;
  final String url;
  const ProjectCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.banner,
    required this.url,
  });

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield a(href: url, target: Target.blank, classes: 'certificate-card', [
      div(
          classes: 'certificate-image',
          styles: Styles.combine([
            Styles.background(
              image: ImageStyle.url(banner),
              size: BackgroundSize.cover,
            ),
          ]),
          []),
      img(src: icon, height: 80),
      span(classes: 'certificate-title', [
        text(title),
      ]),
      span(classes: 'certificate-description', [
        text(description),
      ]),
    ]);
  }

  @css
  static final List<StyleRule> styles = [
    css('.certificate-card')
        .flexbox(
          direction: FlexDirection.column,
          alignItems: AlignItems.center,
          justifyContent: JustifyContent.center,
        )
        .box(
          height: 250.px,
          width: 380.px,
          radius: BorderRadius.circular(12.px),
          margin: EdgeInsets.only(top: 25.px, left: 10.px, right: 10.px),
        )
        .background(
          color: themeDarkGreyColor,
        )
        .text(
          decoration: TextDecoration.none,
        ),
    css('.certificate-card:hover').box(
      shadow: BoxShadow(
        color: themePrimaryColor,
        offsetX: 0.px,
        offsetY: 0.px,
        blur: 8.px,
        spread: 2.px,
      ),
      transition: Transition('box-shadow', duration: 500),
      cursor: Cursor.pointer,
    ),
    css('.certificate-image').box(
      height: 250.px,
      width: 380.px,
    ),
    css('.certificate-description')
        .text(
          fontSize: 12.px,
          align: TextAlign.center,
        )
        .box(
          padding: EdgeInsets.symmetric(horizontal: 10.px),
          margin: EdgeInsets.only(top: 10.px),
        ),
    css('.certificate-image').box(
      opacity: 1.0,
      radius: BorderRadius.circular(12.px),
      position: Position.absolute(),
    ),
    css('.certificate-image:hover').box(
      opacity: 0,
      transition: Transition('opacity', duration: 500),
    ),
  ];
}
