import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool isLogin = true;
  String error = "";

  Future<void> submit() async {
    setState(() => error = "");
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );
        final uid = cred.user!.uid;
        await FirebaseDatabase.instance.ref("accounts/$uid").update({
          "email": email.text.trim().toLowerCase(),
          "homes": {
            "home1": {
              "name": "Home 1",
              "devices": {},

              "alarm": {"enabled": false, "start": "23:00", "end": "06:00"},
            },
          },
          "alarm": {"enabled": false, "start": "23:00", "end": "06:00"},
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == "user-not-found") {
          error = "Sai tài khoản";
        } else if (e.code == "wrong-password") {
          error = "Sai mật khẩu";
        } else if (e.code == "email-already-in-use") {
          error = "Email đã tồn tại";
        } else if (e.code == "weak-password") {
          error = "Mật khẩu quá yếu";
        } else {
          error = e.message ?? "Lỗi đăng nhập";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 340,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "SafeHome",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: pass,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password"),
              ),

              if (error.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(error, style: TextStyle(color: Colors.red)),
                ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: submit,
                child: Text(isLogin ? "Login" : "Sign Up"),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    error = "";
                  });
                },
                child: Text(
                  isLogin
                      ? "Chưa có tài khoản? Đăng ký"
                      : "Đã có tài khoản? Đăng nhập",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
