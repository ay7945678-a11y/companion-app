import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
// MAIN NAVIGATION (सीरियल-वाइज़ नेविगेशन)
// -------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // डिफॉल्ट सबसे पहले KYC टैब पर खुलेगा
  bool isKycApproved = false; // KYC का स्टेटस

  // सीरियल: 1. KYC -> 2. एक्सप्लोर -> 3. बुकिंग्स -> 4. प्रोफाइल
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _updateScreens();
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
// STEP 1: KYC VERIFICATION SCREEN (सबसे पहला स्टेप)
// -------------------------------------------------------------
class KycVerificationScreen extends StatefulWidget {
  final VoidCallback onKycSubmitted;
  const KycVerificationScreen({Key? key, required this.onKycSubmitted}) : super(key: key);

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  String _selectedDoc = 'Aadhaar Card';
  bool _isSubmitted = false;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  final List<String> _docTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Driving License',
    'Voter ID'
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('इमेज चुनने में समस्या: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.indigo),
                title: const Text('गैलरी से चुनें'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.indigo),
                title: const Text('कैमरा से फोटो खींचें'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('स्टेप 1: KYC वेरिफिकेशन'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
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
              onTap: _showImagePickerModal,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedImage != null ? Colors.green : Colors.indigo,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.indigo.withOpacity(0.05),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, size: 50, color: Colors.indigo),
                          SizedBox(height: 8),
                          Text('डॉक्यूमेंट की फोटो (Front & Back) अपलोड करें'),
                          SizedBox(height: 4),
                          Text('(टैप करके गैलरी/कैमरा से चुनें)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            
            if (_selectedImage != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  label: const Text('फोटो हटाएं', style: TextStyle(color: Colors.red)),
                ),
              ),

            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSubmitted ? Colors.green : Colors.indigo,
                ),
                onPressed: _isSubmitted
                    ? null
                    : () {
                        if (_selectedImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ कृपया पहले डॉक्यूमेंट की फोटो अपलोड करें!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isSubmitted = true;
                        });
                        widget.onKycSubmitted();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ KYC जमा हुआ! अब आप एक्सप्लोर करके बुकिंग कर सकते हैं।'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                child: Text(
                  _isSubmitted ? 'KYC सबमिट हो गया (Pending Verification)' : 'KYC सबमिट करें',
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
// STEP 2: HOME & LISTING SCREEN (एक्सप्लोर साथी)
// -------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  final bool isKycDone;
  const HomeScreen({Key? key, required this.isKycDone}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('स्टेप 2: Companion Finder'),
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
                  if (!isKycDone) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ बुकिंग के लिए पहले KYC पूरा करना अनिवार्य है!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

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
// STEP 3: BOOKING & RAZORPAY PAYMENT SCREEN (अंतिम स्टेप)
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
      appBar: AppBar(title: const Text('स्टेप 3: कन्फर्म बुकिंग & पेमेंट'), backgroundColor: Colors.indigo),
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
// BOOKINGS LIST & PROFILE
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
