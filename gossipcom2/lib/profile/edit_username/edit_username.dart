import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/register/username.dart';
import 'package:gossipcom/profile/edit_username/edit_username_provider.dart';
import 'package:provider/provider.dart';

class EditUsername extends StatelessWidget {
  const EditUsername({super.key});

static final UsernameGenderValidator _genderValidator = UsernameGenderValidator();

  @override
  Widget build(BuildContext context) {
    final editUserNameProvider = Provider.of<EditUserNameProvider>(context);
    

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 50),
            child: Row(
              children: [
                Image.asset("assets/app_logo.png", height: 60, width: 60),
              ],
            ),
          ),
          const SizedBox(height: 120),
          Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)
              ),
              child: Image.asset("reg_assets/welcome.png")),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45.0),
            child: TextFormField(
              controller: editUserNameProvider.controller,
              obscureText: false,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: _localValidator,
              decoration: InputDecoration(
                errorMaxLines: 2,
                fillColor: Theme.of(context).colorScheme.secondary,
                filled: true,
                hintText: "Username",
                hintStyle: const TextStyle(color: Color(0xFF828282)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          InkWell(
            onTap: editUserNameProvider.isLoading
                ? null
                : () async {
                    await editUserNameProvider.submitReview(context);
                    if (!editUserNameProvider.isLoading &&
                        editUserNameProvider.controller.text
                            .trim()
                            .isNotEmpty) {}
                  },
            child: Container(
              height: 52,
              width: 315,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: editUserNameProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
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
        ],
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
