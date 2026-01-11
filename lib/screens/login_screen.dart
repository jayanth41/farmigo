import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String verificationId = "";
  bool otpSent = false;

  void sendOTP() async {
    String phoneNumber = phoneController.text.trim();

    // Remove any spaces
    phoneNumber = phoneNumber.replaceAll(" ", "");

    // If user entered with +91, use it as is
    if (phoneNumber.startsWith("+91")) {
      // Already has country code
    } else if (phoneNumber.startsWith("91")) {
      // Has 91 but no +, add +
      phoneNumber = "+$phoneNumber";
    } else {
      // Just 10 digits, add +91
      phoneNumber = "+91$phoneNumber";
    }

    if (phoneNumber.isEmpty || phoneNumber.length < 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 10-digit phone number")),
      );
      return;
    }

    // TODO: Uncomment when Firebase Auth is working
    // await FirebaseAuth.instance.verifyPhoneNumber(
    //   phoneNumber: phoneNumber,
    //   verificationCompleted: (PhoneAuthCredential credential) async {
    //     await FirebaseAuth.instance.signInWithCredential(credential);
    //   },
    //   verificationFailed: (FirebaseAuthException e) {
    //     ScaffoldMessenger.of(context)
    //         .showSnackBar(SnackBar(content: Text(e.message!)));
    //   },
    //   codeSent: (String verId, int? resendToken) {
    //     setState(() {
    //       verificationId = verId;
    //       otpSent = true;
    //     });
    //   },
    //   codeAutoRetrievalTimeout: (String verId) {
    //     verificationId = verId;
    //   },
    // );

    // Temporary: Just show OTP field
    setState(() {
      otpSent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text("OTP sent to $phoneNumber (Firebase disabled)")),
    );
  }

  void verifyOTP() async {
    String otp = otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter OTP")),
      );
      return;
    }

    // TODO: Uncomment when Firebase Auth is working
    // try {
    //   PhoneAuthCredential credential = PhoneAuthProvider.credential(
    //     verificationId: verificationId,
    //     smsCode: otp,
    //   );
    //
    //   await FirebaseAuth.instance.signInWithCredential(credential);
    //
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Login Successful")),
    //   );
    //
    //   // Navigate to home screen after successful login
    //   if (mounted) {
    //     Navigator.pushReplacementNamed(context, '/home');
    //   }
    // } on FirebaseAuthException catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("Error: ${e.message}")),
    //   );
    // }

    // Temporary: Just navigate to home
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login Successful (Firebase disabled)")),
    );
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Phone Login")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                hintText: "Enter 10 digit number",
              ),
            ),
            const SizedBox(height: 20),

            if (otpSent)
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "OTP",
                ),
              ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: otpSent ? verifyOTP : sendOTP,
              child: Text(otpSent ? "Verify OTP" : "Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}