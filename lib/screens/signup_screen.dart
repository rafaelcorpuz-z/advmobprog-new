import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';

import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _age = TextEditingController();
  final _contactNo = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_fName, _lName, _age, _contactNo, _username, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String label) =>
      v == null || v.trim().isEmpty ? 'Enter $label' : null;

  String? _validateAge(String? v) {
    final age = int.tryParse(v ?? '');
    if (age == null) return 'Enter a valid age';
    if (age < 1 || age > 120) return 'Age must be 1-120';
    return null;
  }

  String? _validateContact(String? v) {
    if (v == null || !RegExp(r'^[0-9+\-\s]{7,15}$').hasMatch(v.trim())) {
      return 'Enter a valid contact number';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Add a lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Add a number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(v)) {
      return 'Add a special character';
    }
    return null;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cred = await _userService.createAccount(
        email: _email.text.trim(),
        password: _password.text,
      );
      await _userService.updateUsername(username: _username.text.trim());
      await _userService.saveProfileExtras(cred.user!.uid, {
        'fName': _fName.text.trim(),
        'lName': _lName.text.trim(),
        'age': _age.text.trim(),
        'contactNo': _contactNo.text.trim(),
      });
      await _userService.syncUserToFirestore(rethrowErrors: true);
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false,
          arguments: userData);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } catch (e) {
      _showError('Sign up failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget _field(
    TextEditingController c,
    String label,
    String? Function(String?) validator, {
    TextInputType? type,
    bool password = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        obscureText: password && _obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF7F9FD),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: password
              ? IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F8),
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: const Color(0xFF3445A2),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 360,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
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
                  _field(_fName, 'First name', (v) => _required(v, 'first name')),
                  _field(_lName, 'Last name', (v) => _required(v, 'last name')),
                  _field(_age, 'Age', _validateAge, type: TextInputType.number),
                  _field(_contactNo, 'Contact number', _validateContact,
                      type: TextInputType.phone),
                  _field(_username, 'Username', (v) => _required(v, 'username')),
                  _field(_email, 'Email address', _validateEmail,
                      type: TextInputType.emailAddress),
                  _field(_password, 'Password', _validatePassword,
                      password: true),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Password: 8+ characters with uppercase, lowercase, number and special character.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3445A2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Create account',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Already have an account? Log in'),
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