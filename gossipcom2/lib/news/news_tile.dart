import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gossipcom/news/news_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsTile extends StatefulWidget {
  final String category;
  final String news;
  final String link;
  final String title;
  final String? imageLink;

  const NewsTile(
      {super.key,
      required this.category,
      required this.news,
      required this.link,
      required this.title,
      this.imageLink});

  @override
  State<NewsTile> createState() => _NewsTileState();
}

class _NewsTileState extends State<NewsTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22.0),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewsDetailScreen(
                  category: widget.category,
                  news: widget.news,
                  link: widget.link,
                  title: widget.title,
                  imageLink: widget.imageLink,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            // height: 550, // Fixed total height
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onTertiary,
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        widget.category,
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.imageLink != null)
                          Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: widget.imageLink!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
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

                                // Image.network(widget.imageLink!,fit:BoxFit.cover,errorBuilder: (context,error,stackTrace){
                              ),
                            ),
                          ),
                        Text(
                          widget.title,
                          style: GoogleFonts.dmSerifText(
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          widget.news,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 4,
                          style: GoogleFonts.dmSerifText(
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final Uri uri = Uri.parse(widget.link.trim());
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Could Not launch uel")));
                            }
                          },
                          child: Text(
                            widget.link,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSerifText(
                              fontWeight: FontWeight.w400,
                              color: Colors.blue,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const Divider(
                  //   thickness: 2,
                  //   color: Color(0x82979797),
                  // ),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     InkWell(
                  //         child: Text("❤️‍🔥", style: _emojiStyle()),
                  //         onTap: () {
                  //           Confetti.launch(context,
                  //               particleBuilder: (index) =>
                  //                   Emoji(emoji: '️❤️‍🔥‍'),
                  //               options: const ConfettiOptions(
                  //                   decay: 0.9,
                  //                   startVelocity: 100,

                  //                   particleCount: 100, spread: 50, y: 0.6));
                  //         }),
                  //     InkWell(
                  //       child: Text("😍", style: _emojiStyle()),
                  //       onTap: () {
                  //         Confetti.launch(context,

                  //             particleBuilder: (index) => Emoji(emoji: "😍"),
                  //             options: const ConfettiOptions(
                  //                 particleCount: 100, spread: 70, y: 0.6));
                  //       },
                  //     ),
                  //     InkWell(
                  //       child: Text("😂", style: _emojiStyle()),
                  //       onTap: () {
                  //         Confetti.launch(context,
                  //             particleBuilder: (index) => Emoji(emoji: "😂"),
                  //             options: const ConfettiOptions(
                  //                 particleCount: 100, spread: 70, y: 0.6));
                  //       },
                  //     ),
                  //     InkWell(
                  //       child: Text("🤯", style: _emojiStyle()),
                  //       onTap: () {
                  //         Confetti.launch(context,
                  //             particleBuilder: (index) => Emoji(emoji: "🤯"),
                  //             options: const ConfettiOptions(
                  //                 particleCount: 100, spread: 70, y: 0.6));
                  //       },
                  //     ),
                  //     InkWell(
                  //       child: Text("💀", style: _emojiStyle()),
                  //       onTap: () {
                  //         Confetti.launch(context,
                  //             particleBuilder: (index) => Emoji(emoji: "💀"),
                  //             options: const ConfettiOptions(
                  //                 particleCount: 100, spread: 70, y: 0.6));
                  //       },
                  //     ),
                  //     InkWell(
                  //       child: Text("😢", style: _emojiStyle()),
                  //       onTap: () {
                  //         Confetti.launch(context,
                  //             particleBuilder: (index) => Emoji(emoji: "😢"),
                  //             options: const ConfettiOptions(
                  //                 particleCount: 100, spread: 70, y: 0.6));
                  //       },
                  //     ),
                  //     InkWell(
                  //       child: Text("🤔", style: _emojiStyle()),
                  //       onTap: () {
                  //         Confetti.launch(context,
                  //             particleBuilder: (index) => Emoji(emoji: "🤔"),
                  //             options: const ConfettiOptions(
                  //                 particleCount: 100, spread: 70, y: 0.6));
                  //       },
                  //     ),
                  //     InkWell(
                  //       child: Text("💡", style: _emojiStyle()),
                  //       onTap: () {
                  //         Confetti.launch(context,
                  //             particleBuilder: (index) => Emoji(emoji: "💡"),
                  //             options: const ConfettiOptions(
                  //                 particleCount: 100, spread: 70, y: 0.6));
                  //       },
                  //     ),
                  //   ],
                  // )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TextStyle _emojiStyle() {
  //   return GoogleFonts.dmSerifText(
  //     fontWeight: FontWeight.w400,
  //     color: const Color(0xFF060606),
  //     fontSize: 18,
  //   );
  // }
}
