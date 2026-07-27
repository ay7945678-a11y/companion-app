import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialize note: $e");
  }
  runApp(const PartnerApp());
}

class PartnerApp extends StatelessWidget {
  const PartnerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Companion Partner App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const AuthGateScreen(),
    );
  }
}

// -------------------------------------------------------------
// AUTH GATE: यूजर लॉगिन चेक
// -------------------------------------------------------------
class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// -------------------------------------------------------------
// LOGIN SCREEN
// -------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginOrRegister() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      if (email.isEmpty || password.isEmpty) {
        throw 'कृपया ईमेल और पासवर्ड दर्ज करें।';
      }

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } catch (_) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('लॉगिन / साइन-अप'), backgroundColor: Colors.indigo),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Email ID'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      onPressed: _loginOrRegister,
                      child: const Text('लॉगिन करें / अकाउंट बनाएं', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// MAIN NAVIGATION
// -------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool isKycApproved = false;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _updateScreens();
    _checkKycStatusInFirestore();
  }

  void _checkKycStatusInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('kyc_requests').doc(user.uid).get();
      if (doc.exists && doc.data()?['status'] == 'Approved') {
        setState(() {
          isKycApproved = true;
          _updateScreens();
        });
      }
    }
  }

  void _updateScreens() {
    _screens = [
      KycVerificationScreen(onKycSubmitted: () {
        setState(() {
          isKycApproved = true;
          _updateScreens();
        });
      }),
      HomeScreen(isKycDone: isKycApproved),
      const BookingScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: '1. KYC'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: '2. एक्सप्लोर'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: '3. बुकिंग'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '4. प्रोफाइल'),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// STEP 1: KYC VERIFICATION SCREEN
// -------------------------------------------------------------
class KycVerificationScreen extends StatefulWidget {
  final VoidCallback onKycSubmitted;
  const KycVerificationScreen({Key? key, required this.onKycSubmitted}) : super(key: key);

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  String _selectedDoc = 'Aadhaar Card';
  bool _isUploading = false;
  bool _isSubmitted = false;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();
  final List<String> _docTypes = ['Aadhaar Card', 'PAN Card', 'Driving License', 'Voter ID'];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('इमेज चुनने में समस्या: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadKycToFirebase() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ कृपया पहले डॉक्यूमेंट की फोटो अपलोड करें!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();

      final ref = FirebaseStorage.instance.ref().child('kyc_docs').child('$uid.jpg');
      await ref.putFile(_selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('kyc_requests').doc(uid).set({
        'uid': uid,
        'email': user?.email ?? 'Unknown',
        'docType': _selectedDoc,
        'imageUrl': imageUrl,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() => _isSubmitted = true);
      widget.onKycSubmitted();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ KYC डेटाबेस में जमा हुआ!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('अपलोड एरर: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('स्टेप 1: KYC वेरिफिकेशन'), backgroundColor: Colors.indigo),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('पहचान पत्र चुनें और अपलोड करें', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedDoc,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Document Type'),
              items: _docTypes.map((doc) => DropdownMenuItem(value: doc, child: Text(doc))).toList(),
              onChanged: (val) => setState(() => _selectedDoc = val!),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(leading: const Icon(Icons.photo_library), title: const Text('गैलरी से चुनें'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                        ListTile(leading: const Icon(Icons.photo_camera), title: const Text('कैमरा से खींचें'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedImage != null ? Colors.green : Colors.indigo, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.indigo.withOpacity(0.05),
                ),
                child: _selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, size: 50, color: Colors.indigo),
                          SizedBox(height: 8),
                          Text('डॉक्यूमेंट की फोटो अपलोड करें'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _isSubmitted ? Colors.green : Colors.indigo),
                      onPressed: _isSubmitted ? null : _uploadKycToFirebase,
                      child: Text(_isSubmitted ? 'KYC जमा हो गया (Pending)' : 'KYC डेटाबेस में सबमिट करें', style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// HOME, BOOKING & PROFILE
// -------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  final bool isKycDone;
  const HomeScreen({Key? key, required this.isKycDone}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('स्टेप 2: Companion Finder'), backgroundColor: Colors.indigo),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('Companion Profile #${index + 1}'),
              subtitle: const Text('Verified • ₹500/घंटा'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () {
                  if (!isKycDone) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⚠️ बुकिंग के लिए पहले KYC होना अनिवार्य है!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentAndBookingScreen(amount: 500.0, bookingId: 'BK1001')));
                },
                child: const Text('बुक करें', style: TextStyle(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PaymentAndBookingScreen extends StatefulWidget {
  final double amount;
  final String bookingId;
  const PaymentAndBookingScreen({Key? key, required this.amount, required this.bookingId}) : super(key: key);

  @override
  State<PaymentAndBookingScreen> createState() => _PaymentAndBookingScreenState();
}

class _PaymentAndBookingScreenState extends State<PaymentAndBookingScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse res) {
      FirebaseFirestore.instance.collection('bookings').add({
        'bookingId': widget.bookingId,
        'amount': widget.amount,
        'paymentId': res.paymentId,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('भुगतान सफल! ID: ${res.paymentId}'), backgroundColor: Colors.green));
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse res) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('भुगतान विफल: ${res.message}'), backgroundColor: Colors.red));
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('स्टेप 3: कन्फर्म बुकिंग & पेमेंट'), backgroundColor: Colors.indigo),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
          onPressed: () {
            _razorpay.open({
              'key': 'rzp_test_TIYKekAWrpcZBR',
              'amount': (widget.amount * 100).toInt(),
              'name': 'Companion Partner App',
              'description': 'Booking ID: ${widget.bookingId}',
            });
          },
          icon: const Icon(Icons.payment, color: Colors.white),
          label: Text('Pay ₹${widget.amount.toStringAsFixed(0)} Now', style: const TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }
}

class BookingScreen extends StatelessWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('मेरी बुकिंग्स'), backgroundColor: Colors.indigo),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('कोई बुकिंग नहीं मिली।'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Booking ID: ${data['bookingId']}'),
                subtitle: Text('Payment ID: ${data['paymentId']}'),
                trailing: Text('₹${data['amount']}'),
              );
            },
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('मेरी प्रोफाइल'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 10),
            Text(user?.email ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
