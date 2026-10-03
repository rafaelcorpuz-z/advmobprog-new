import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../utils/login_type.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // username OR email
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();
  LoginType _loginType = LoginType.dummyJson;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return; // FIXED: no stuck spinner
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> userData;
      if (_loginType == LoginType.dummyJson) {
        userData = await _userService.loginUser(
          _identifierController.text.trim(),
          _passwordController.text,
        );
      } else {
        await _userService.signIn(
          email: _identifierController.text.trim(),
          password: _passwordController.text,
        );
        userData = await _userService.getUserData();
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } catch (error) {
      _showError('Login failed: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _decoration(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F9FD),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  @override
  Widget build(BuildContext context) {
    final isFirebase = _loginType == LoginType.firebase;
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 340,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/icons/nuicon.png',
                            width: 54, height: 54, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      const Text('Welcome',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3445A2))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<LoginType>(
                    segments: const [
                      ButtonSegment(
                          value: LoginType.dummyJson, label: Text('DummyJSON')),
                      ButtonSegment(
                          value: LoginType.firebase, label: Text('Firebase')),
                    ],
                    selected: {_loginType},
                    onSelectionChanged: (s) => setState(() {
                      _loginType = s.first;
                      _identifierController.clear();
                    }),
                  ),
                  const SizedBox(height: 20),
                  Text(isFirebase ? 'Email' : 'Username',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: isFirebase
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (isFirebase ? 'Enter email' : 'Enter username')
                        : null,
                    decoration: _decoration(isFirebase ? 'Email' : 'Username'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Password',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter password' : null,
                    decoration: _decoration(
                      'Password',
                      suffix: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3445A2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Log in',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('Create a Firebase account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}