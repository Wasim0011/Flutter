import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class GlobalShare {
  static void shareThought({
    required BuildContext context,
    required String userName,
    required String thought,
    String? thoughtId,
  }) {
    final text = """
🗣️ Gossip by $userName

$thought

🔥 Read more on GossipCom
""";

    Share.share(text);
  }
}
