import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase init error: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APNs Token Display',
      home: TokenScreen(),
    );
  }
}

class TokenScreen extends StatefulWidget {
  @override
  _TokenScreenState createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _token;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _getToken();
  }

  Future<void> _getToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // طلب الإذن لكلا المنصتين
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print("📱 Permission status: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        setState(() {
          _hasPermission = true;
        });
      } else {
        setState(() {
          _hasPermission = false;
          _errorMessage = '❌ الإذن مرفوض: ${settings.authorizationStatus}';
        });
        _isLoading = false;
        return;
      }

      // انتظار قليل للتأكد من تهيئة APNs
      await Future.delayed(Duration(milliseconds: 500));

      // الحصول على الـ Token
      String? token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        print("✅ Token received: ${token.substring(0, 20)}...");
        setState(() {
          _token = token;
          _isLoading = false;
        });
      } else {
        throw Exception('الـ Token فارغ');
      }

    } catch (e) {
      print("❌ Error getting token: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ: $e';
        _token = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('APNs Token'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _getToken,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasPermission ? Icons.notifications_active : Icons.notifications_off,
              size: 80,
              color: _hasPermission ? Colors.green : Colors.orange,
            ),
            SizedBox(height: 32),
            Text(
              'حالة الجهاز:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // ✅ الـ if-else chain المُصحح
            if (_isLoading)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري الحصول على الـ Token...',
                      style: TextStyle(fontSize: 16)),
                ],
              )
            else if (_token != null && _token!.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ الـ Token جاهز:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    SelectableText(
                      _token!,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 40),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red[800], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _getToken,
                        icon: Icon(Icons.refresh),
                        label: Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.block, color: Colors.orange, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'لا يمكن الحصول على الـ Token بدون إذن الإشعارات',
                        style: TextStyle(color: Colors.orange[800], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getToken,
              icon: Icon(Icons.refresh),
              label: Text('تحديث الـ Token'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
