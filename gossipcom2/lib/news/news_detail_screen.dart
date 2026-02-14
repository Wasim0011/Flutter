import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailScreen extends StatelessWidget {
  final String category;
  final String news;
  final String link;
  final String title;
  final String? imageLink;

  const NewsDetailScreen({
    super.key,
    required this.category,
    required this.news,
    required this.link,
    required this.title,
    this.imageLink,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.home_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                "Back Home",
                style: GoogleFonts.dmSerifText(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: GoogleFonts.dmSerifText(
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: 20,
                  ),
                )
              ],
            ),
            const Divider(
              thickness: 2,
              color: Color(0x82979797),
            ),
            const SizedBox(height: 16),
            if (imageLink != null)
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageLink!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.grey[300],
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Text(
                          "No Image Available",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.dmSerifText(
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSecondary,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              news,
              style: GoogleFonts.dmSerifText(
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSecondary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final Uri uri = Uri.parse(link.trim());
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could Not launch url")));
                  }
                }
              },
              child: Text(
                link,
                style: GoogleFonts.dmSerifText(
                  fontWeight: FontWeight.w400,
                  color: Colors.blue,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
