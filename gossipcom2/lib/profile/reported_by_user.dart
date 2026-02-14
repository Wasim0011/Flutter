import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/auth_service.dart';

class ReportedByUser extends StatefulWidget {
  const ReportedByUser({super.key});

  @override
  State<ReportedByUser> createState() => _ReportedByUserState();
}

class _ReportedByUserState extends State<ReportedByUser> {
  final authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  Future<int> getReportsCount() async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) throw Exception("User not logged in");

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data()!.containsKey('reports')) {
        final List reports = doc.data()!['reports'];
        return reports.length;
      } else {
        return 0;
      }
    } catch (e) {
      debugPrint('Error fetching report count: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenWidth * 0.13),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios),
              ),
              SizedBox(width: screenWidth * 0.24),
              Text(
                "Strike by User",
                style: GoogleFonts.dmSerifText(
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FutureBuilder<int>(
              future: getReportsCount(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("");
                } else if (snapshot.hasError) {
                  return const Text("Failed to load strikes");
                } else {
                  final count = snapshot.data ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("⚠️ "),
                      const SizedBox(
                        width: 20,
                      ),
                      Flexible(
                        child: Text(
                          count > 0
                              ? "Be Aware, You got $count strike${count > 1 ? 's' : ''}"
                              : "You have no strikes",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Divider(thickness: 1, color: Color(0x82979797)),
          )
        ],
      ),
    );
  }
}
