import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/profile/report_user/report_user_provider.dart';
import 'package:provider/provider.dart';

class ReportUser extends StatelessWidget {
  final String userId;
  final String userName;
  const ReportUser({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    final reportUserProvider = Provider.of<ReportUserProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: screenWidth * 0.13),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: screenWidth * 0.06),
                Image.asset(
                  "assets/app_logo.png",
                  height: 60,
                  width: 60,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                Text(
                  "Strike / Report a User-$userName",
                  style: GoogleFonts.dmSerifText(
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            ...reportUserProvider.switchStates.entries.map((entry) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      CupertinoSwitch(
                        activeColor: const Color(0xFF6363D5),
                        value: entry.value,
                        onChanged: (bool value) {
                          reportUserProvider.toggleSwitch(entry.key, value);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: reportUserProvider.reportTextController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintStyle: TextStyle(color: Color(0xFF979797)),
                      hintText: 'Write in detail...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: reportUserProvider.isLoading
                  ? null
                  : () {
                      reportUserProvider.submitReport(userId, context);
                    },
              child: Container(
                height: 52,
                width: 315,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: reportUserProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Report",
                          style: GoogleFonts.abhayaLibre(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
