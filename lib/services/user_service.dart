import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart';
import '../utils/login_type.dart';

/// One class the UI talks to. It hides whether the session comes from
/// DummyJSON (REST API) or Firebase Authentication (SDK).
class UserService {
  Map<String, dynamic> data = {};

  // Keys wiped on sign out (profile extras per Firebase uid are kept).
  static const _sessionKeys = [
    'id', 'uid', 'username', 'email', 'firstName', 'lastName', 'gender',
    'image', 'accessToken', 'refreshToken', 'token', 'loginType',
  ];

  // ---------------------------------------------------------------------------
  // DUMMYJSON
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$apiHost/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );
    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      await setLoginType(LoginType.dummyJson);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// Save DummyJSON user data to SharedPreferences based on the User model
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);
    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  // ---------------------------------------------------------------------------
  // FIREBASE AUTH
  // ---------------------------------------------------------------------------
  final fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;

  fb.User? get currentUser => firebaseAuth.currentUser;

  Stream<fb.User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<fb.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveFirebaseSession(cred.user!);
    await syncUserToFirestore(rethrowErrors: true);
    return cred;
  }

  Future<fb.UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final cred = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveFirebaseSession(cred.user!);
    return cred;
  }

  /// Clears the session/token of BOTH login types.
  Future<void> signOut() async {
    if (await getLoginType() == LoginType.firebase ||
        firebaseAuth.currentUser != null) {
      await firebaseAuth.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    for (final k in _sessionKeys) {
      await prefs.remove(k);
    }
  }

  Future<void> updateUsername({required String username}) async {
    final prefs = await SharedPreferences.getInstance();
    if (await getLoginType() == LoginType.firebase && currentUser != null) {
      await currentUser!.updateDisplayName(username);
      await currentUser!.reload();
    }
    // DummyJSON does not persist edits, so only the local copy changes.
    await prefs.setString('username', username);
    if (await getLoginType() == LoginType.firebase) await syncUserToFirestore();
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final user = currentUser!;
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('extras_${user.uid}');
    try {
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).delete();
    } catch (e) {
      debugPrint('Firestore user delete failed: $e');
    }
    await user.delete();
    await signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  Future<void> _saveFirebaseSession(fb.User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', LoginType.firebase.name);
    await prefs.setString('uid', user.uid);
    await prefs.setString('email', user.email ?? '');
    await prefs.setString(
        'username', user.displayName ?? (user.email ?? '').split('@').first);
    // Firebase refreshes this ID token automatically (about every hour).
    await prefs.setString('token', await user.getIdToken() ?? '');
  }

  /// Saves/updates this account in Firestore so it appears in other people's
  /// chat list. Callers can surface write failures when the profile is needed.
  Future<void> syncUserToFirestore({bool rethrowErrors = false}) async {
    try {
      final u = currentUser;
      if (u == null) return;
      final d = await getUserData();
      final doc = <String, dynamic>{
        'uid': u.uid,
        'email': u.email ?? '',
        'username': d['username'],
        'firstName': d['firstName'],
        'lastName': d['lastName'],
        'age': d['age'],
        'contactNo': d['contactNo'],
      };
      // Do not overwrite good data with empty values.
      doc.removeWhere((k, v) => k != 'uid' && k != 'email' && (v == null || v.toString().isEmpty));
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(u.uid)
          .set(doc, SetOptions(merge: true));
    } catch (e) {
      debugPrint('syncUserToFirestore failed: $e');
      if (rethrowErrors) rethrow;
    }
  }

  // Extra signup fields (fName, lName, age, contactNo) kept per account.
  Future<void> saveProfileExtras(String uid, Map<String, String> extras) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extras_$uid', jsonEncode(extras));
  }

  Future<Map<String, dynamic>> _loadProfileExtras(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('extras_$uid');
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // SHARED
  // ---------------------------------------------------------------------------
  Future<void> setLoginType(LoginType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', type.name);
  }

  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') == LoginType.firebase.name
        ? LoginType.firebase
        : LoginType.dummyJson;
  }

  /// Retrieve user data for whichever login type is active.
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final type = await getLoginType();
    final token = prefs.getString('token') ?? prefs.getString('accessToken') ?? '';

    if (type == LoginType.firebase && currentUser != null) {
      final u = currentUser!;
      final extras = await _loadProfileExtras(u.uid);
      return {
        'loginType': type.name,
        'id': u.uid,
        'username': u.displayName ?? prefs.getString('username') ?? '',
        'email': u.email ?? '',
        'firstName': extras['fName'] ?? '',
        'lastName': extras['lName'] ?? '',
        'age': extras['age'] ?? '',
        'contactNo': extras['contactNo'] ?? '',
        'gender': '',
        'image': u.photoURL ?? '',
        'token': token,
      };
    }

    return {
      'loginType': LoginType.dummyJson.name,
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': token,
    };
  }

  Future<bool> isLoggedIn() async {
    if (firebaseAuth.currentUser != null) return true;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('accessToken') ?? '';
    return token.isNotEmpty;
  }
}