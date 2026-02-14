import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/register/select_topic.dart';

class Username extends StatefulWidget {
  Username({super.key});

  @override
  State<Username> createState() => _UsernameState();
}

class _UsernameState extends State<Username> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController userName = TextEditingController();
  final UsernameGenderValidator _genderValidator = UsernameGenderValidator();

  String? firstName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getFirstName();
  }

  Future<void> _getFirstName() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      if (doc.exists) {
        setState(() {
          firstName = doc.data()?['firstName'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          // Handle any cleanup if needed
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.1),
              // Add back button
              Row(
                children: [
                  SizedBox(width: 20),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back_ios, size: 32),
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(height: screenHeight * 0.2),
              Image.asset("assets/userHeader.png"),
              const SizedBox(
                height: 40,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45.0),
                child: TextFormField(
                  controller: userName,
                  obscureText: false,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: _localValidator,
                  decoration: InputDecoration(
                    errorMaxLines: 2,
                    fillColor: Theme.of(context).colorScheme.secondary,
                    filled: true,
                    hintText: "Enter Username",
                    hintStyle:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {

print("Continue button pressed");

                  if (userName.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "UserName cannot be empty!",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }

// --- gender validation ---
                    final detected = _localValidator(userName.text);
                    if (detected != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(detected),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                  if (userName.text.trim().isNotEmpty) {
                    if (firstName != null &&
                        userName.text.trim().toLowerCase() ==
                            firstName!.toLowerCase()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Username and Firstname can't be the same"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    print(userName.text);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SelectTopic(userName: userName.text)));
                  }
                },
                child: Container(
                  height: 52,
                  width: 315,
                  decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(30)),
                  child: Center(
                    child: Text(
                      "Continue",
                      style: GoogleFonts.abhayaLibre(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50.0, vertical: 30),
                child: Text(
                  "Note: Choose a username that doesn’t reveal your gender. You can use a favorite character, object, or something creative. Staying anonymous is totally okay.",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: Color(0xFF828282)),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String? _localValidator(String? v) {
    final s = v ?? '';
    if (s.trim().isEmpty) return 'Enter a username';
    if (s.trim().length < 3) return 'Username too short';
    final detected = _genderValidator.detectGender(s);
    if (detected == GenderCheckResult.male) {
      return 'Usernames that indicate male gender are disallowed';
    }
    if (detected == GenderCheckResult.female) {
      return 'Usernames that indicate female gender are disallowed';
    }
    return null;
  }
}

enum GenderCheckResult { male, female, neutral, unknown }

class UsernameGenderValidator {
  // --- Curated common Indian names (short example lists, expand as needed) ---
  // Keep these lowercase
  static final Set<String> maleNames = {
    'rahul',
    'vikram',
    'raj',
    'arjun',
    'amit',
    'ajay',
    'sachin',
    'vijay',
    'suresh',
    'anil',
    'pradeep',
    'sunil',
    'rajesh',
    'manish',
    'deepak',
    'alok',
    'kumar',
    'mohit',
    'rohit',
    'ravindra',
    'amitabh',
    'dev',
    'atul',
    'gautam',
    'naveen',
    'sanjay',
    'pravin',
    'harish',
    'karthik',
    'rajesh',
    'vivek',
    'kumar',
    'sanjay',
    'ajith',
    'pranav',
    'ishaan',
    'varun',
    'abhishek',
    'rishi',
    'yash'
  };

  static final Set<String> femaleNames = {
    'neha',
    'priya',
    'anita',
    'sunita',
    'suman',
    'pooja',
    'preeti',
    'sowmya',
    'shreya',
    'anisha',
    'sneha',
    'neelam',
    'meena',
    'rani',
    'rekha',
    'ritika',
    'divya',
    'isha',
    'manisha',
    'sarika',
    'kavya',
    'pallavi',
    'lakshmi',
    'geeta',
    'smita',
    'amrita',
    'anjali',
    'nisha',
    'radhika',
    'shilpa',
    'tanuja',
    'isha',
    'kiran',
    'asha',
    'kavita',
    'neetu',
    'sonia',
    'simran',
    'mala',
    'jyoti'
  };

  // Titles/explicit gender indicators
  static final Set<String> genderedWords = {
    'male',
    'female',
    'man',
    'woman',
    'boy',
    'girl',
    'mr',
    'mrs',
    'miss',
    'sir',
    'madam',
    'babu',
    'aunty'
  };

  // Configuration
  final bool blockIfContains =
      true; // block substrings containing gender words/names
  final int fuzzyDistanceThreshold = 1; // allow small typos; set 0 to disable

  String _normalize(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  }

  // Simple Levenshtein distance (costly for long strings; ok for small names)
  int _levenshtein(String a, String b) {
    final la = a.length;
    final lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;
    List<int> v0 = List<int>.generate(lb + 1, (i) => i);
    List<int> v1 = List<int>.filled(lb + 1, 0);
    for (int i = 0; i < la; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < lb; j++) {
        int cost = (a[i] == b[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1, // insertion
          v0[j + 1] + 1, // deletion
          v0[j] + cost // substitution
        ].reduce((x, y) => x < y ? x : y);
      }
      final temp = v0;
      v0 = v1;
      v1 = temp;
    }
    return v0[lb];
  }

  // Detect gender tendency from username string
  GenderCheckResult detectGender(String username) {
    final normalized = _normalize(username);
    if (normalized.isEmpty) return GenderCheckResult.unknown;

    final tokens =
        normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    int maleScore = 0;
    int femaleScore = 0;

    // token exact matches
    for (final t in tokens) {
      if (maleNames.contains(t)) maleScore += 3;
      if (femaleNames.contains(t)) femaleScore += 3;
      if (genderedWords.contains(t)) {
        if (['male', 'man', 'boy', 'mr', 'babu'].contains(t)) maleScore += 5;
        if (['female', 'woman', 'girl', 'mrs', 'miss', 'aunty'].contains(t))
          femaleScore += 5;
      }
    }

    // substring checks (e.g., man123 or 123girl)
    if (blockIfContains) {
      for (final g in genderedWords) {
        if (normalized.contains(g)) {
          if (['male', 'man', 'boy', 'mr', 'babu'].contains(g)) maleScore += 4;
          if (['female', 'woman', 'girl', 'mrs', 'miss', 'aunty'].contains(g))
            femaleScore += 4;
        }
      }
      for (final m in maleNames) {
        if (normalized.contains(m)) maleScore += 2;
      }
      for (final f in femaleNames) {
        if (normalized.contains(f)) femaleScore += 2;
      }
    }

    // fuzzy check small typos
    if (fuzzyDistanceThreshold > 0) {
      for (final t in tokens) {
        for (final m in maleNames) {
          if (_levenshtein(t, m) <= fuzzyDistanceThreshold) maleScore += 2;
        }
        for (final f in femaleNames) {
          if (_levenshtein(t, f) <= fuzzyDistanceThreshold) femaleScore += 2;
        }
      }
    }

    if (maleScore == 0 && femaleScore == 0) return GenderCheckResult.neutral;
    return (maleScore > femaleScore)
        ? GenderCheckResult.male
        : (femaleScore > maleScore)
            ? GenderCheckResult.female
            : GenderCheckResult.neutral;
  }
}
