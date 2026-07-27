import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

void main() {
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
      home: const MainNavigationScreen(),
    );
  }
}

// -------------------------------------------------------------
// MAIN NAVIGATION (नीचे के नेविगेशन टैब्स)
// -------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingScreen(),
    const KycVerificationScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'एक्सप्लोर'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'बुकिंग'),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: 'KYC'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'प्रोफाइल'),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. HOME & LISTING SCREEN (साथी खोजना)
// -------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companion Finder'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.indigoAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text('Companion Profile #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Verified User • ₹500/घंटा'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentAndBookingScreen(
                        amount: 500.0,
                        bookingId: 'BK1001',
                      ),
                    ),
                  );
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

// -------------------------------------------------------------
// 2. KYC VERIFICATION SCREEN (आधार, पैन, DL, वोटर ID)
// -------------------------------------------------------------
class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({Key? key}) : super(key: key);

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  String _selectedDoc = 'Aadhaar Card';
  bool _isSubmitted = false;

  final List<String> _docTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Driving License',
    'Voter ID'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC वेरिफिकेशन'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'पहचान पत्र चुनें और अपलोड करें',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedDoc,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Document Type',
              ),
              items: _docTypes.map((String doc) {
                return DropdownMenuItem(value: doc, child: Text(doc));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDoc = val!;
                });
              },
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('फोटो सेलेक्ट करने का ऑप्शन खुला')),
                );
              },
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.indigo, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.indigo.withOpacity(0.05),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 50, color: Colors.indigo),
                    SizedBox(height: 8),
                    Text('डॉक्यूमेंट की फोटो (Front & Back) अपलोड करें'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () {
                  setState(() {
                    _isSubmitted = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('KYC डॉक्यूमेंट सफलता पूर्वक जमा हुए! वेरिफिकेशन चालू है।'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text(
                  _isSubmitted ? 'KYC सबमिट हो गया (Pending)' : 'KYC सबमिट करें',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. BOOKING & RAZORPAY PAYMENT SCREEN (पेमेंट गेटवे)
// -------------------------------------------------------------
class PaymentAndBookingScreen extends StatefulWidget {
  final double amount;
  final String bookingId;

  const PaymentAndBookingScreen({
    Key? key,
    required this.amount,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<PaymentAndBookingScreen> createState() => _PaymentAndBookingScreenState();
}

class _PaymentAndBookingScreenState extends State<PaymentAndBookingScreen> {
  late Razorpay _razorpay;

  // आपकी Razorpay Test Key
  static const String _razorpayKey = 'rzp_test_TIYKekAWrpcZBR';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _startPayment() {
    var options = {
      'key': _razorpayKey,
      'amount': (widget.amount * 100).toInt(),
      'name': 'Companion Partner App',
      'description': 'Booking ID: ${widget.bookingId}',
      'prefill': {'contact': '9876543210', 'email': 'user@example.com'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('भुगतान सफल! Transaction ID: ${response.paymentId}'), backgroundColor: Colors.green),
    );
  }

  void _handleError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('भुगतान विफल: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('कन्फर्म बुकिंग & पेमेंट'), backgroundColor: Colors.indigo),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('कुल बुकिंग शुल्क: ₹${widget.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: _startPayment,
                icon: const Icon(Icons.payment, color: Colors.white),
                label: const Text('Pay Now (Razorpay)', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. BOOKINGS LIST SCREEN
// -------------------------------------------------------------
class BookingScreen extends StatelessWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('मेरी बुकिंग्स'), backgroundColor: Colors.indigo),
      body: const Center(child: Text('आपकी सभी पुरानी व नई बुकिंग्स यहाँ दिखेंगी।')),
    );
  }
}

// -------------------------------------------------------------
// 5. USER PROFILE SCREEN
// -------------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('मेरी प्रोफाइल'), backgroundColor: Colors.indigo),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 40, child: Icon(Icons.person, size: 50)),
            SizedBox(height: 10),
            Text('User Name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Status: KYC Pending / Verified'),
          ],
        ),
      ),
    );
  }
}
