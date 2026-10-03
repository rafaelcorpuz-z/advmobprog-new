import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../utils/login_type.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic> _user = {};
  LoginType _loginType = LoginType.dummyJson;
  bool _loading = true;

  bool get _isFirebase => _loginType == LoginType.firebase;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await _userService.getUserData();
    final type = await _userService.getLoginType();
    if (!mounted) return;
    setState(() {
      _user = data;
      _loginType = type;
      _loading = false;
    });
  }

  String _v(String key) => (_user[key] ?? '').toString();

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _logout() async {
    await _userService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

  // ---- Update username ----
  Future<void> _editUsername() async {
    final c = TextEditingController(text: _v('username'));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update username'),
        content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'New username')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    final name = c.text.trim();
    c.dispose();
    if (ok != true || name.isEmpty) return;
    try {
      await _userService.updateUsername(username: name);
      await _loadUser();
      _msg('Username updated');
    } catch (e) {
      _msg('Update failed: $e');
    }
  }

  // ---- Change password ----
  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: current,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current password')),
            TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'New password (min 8 characters)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Change')),
        ],
      ),
    );
    final cur = current.text;
    final nw = next.text;
    current.dispose();
    next.dispose();
    if (ok != true) return;
    if (nw.length < 8) {
      _msg('New password must be at least 8 characters');
      return;
    }
    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: cur,
        newPassword: nw,
        email: _v('email'),
      );
      _msg('Password changed');
    } on FirebaseAuthException catch (e) {
      _msg(e.message ?? e.code);
    } catch (e) {
      _msg('Failed: $e');
    }
  }

  // ---- Delete account ----
  Future<void> _deleteAccount() async {
    final pw = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This permanently deletes your account. Enter your password to confirm.'),
            TextField(
                controller: pw,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    final password = pw.text;
    pw.dispose();
    if (ok != true) return;
    try {
      await _userService.deleteAccount(email: _v('email'), password: password);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
    } on FirebaseAuthException catch (e) {
      _msg(e.message ?? e.code);
    } catch (e) {
      _msg('Failed: $e');
    }
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF3445A2)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          ],
        ),
      );

  Widget _button(String label, IconData icon, VoidCallback onTap, Color color) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final fullName = '${_v('firstName')} ${_v('lastName')}'.trim();
    final image = _v('image');

    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F8),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF3445A2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: 360,
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: const Color(0xFF2FA084),
                          backgroundImage:
                              image.isNotEmpty ? NetworkImage(image) : null,
                          child: image.isEmpty
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 50)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _v('username').isEmpty ? 'User' : _v('username'),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF283B5F)),
                        ),
                        const SizedBox(height: 6),
                        Chip(
                          label: Text(_isFirebase
                              ? 'Signed in with Firebase'
                              : 'Signed in with DummyJSON'),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              if (fullName.isNotEmpty)
                                _row(Icons.badge_outlined, fullName),
                              _row(Icons.email_outlined, _v('email')),
                              if (_isFirebase) ...[
                                _row(Icons.cake_outlined, 'Age: ${_v('age')}'),
                                _row(Icons.phone_outlined,
                                    'Contact: ${_v('contactNo')}'),
                              ] else ...[
                                _row(Icons.person_outline,
                                    'Gender: ${_v('gender')}'),
                                _row(Icons.numbers, 'User ID: #${_v('id')}'),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _button('Update username', Icons.edit, _editUsername,
                            const Color(0xFF3445A2)),
                        if (_isFirebase) ...[
                          _button('Change password', Icons.lock_reset,
                              _changePassword, const Color(0xFF2FA084)),
                          _button('Delete account', Icons.delete_forever,
                              _deleteAccount, Colors.red),
                        ] else
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              'Change password and delete account are only available for Firebase accounts (DummyJSON is a demo API).',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        _button('Log Out', Icons.logout, _logout,
                            const Color(0xFFB55C66)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}