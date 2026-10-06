import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sell4More Scanner',
      theme: ThemeData.dark(),
      home: const Sell4MoreScanner(),
    );
  }
}

class Sell4MoreScanner extends StatefulWidget {
  const Sell4MoreScanner({super.key});

  @override
  State<Sell4MoreScanner> createState() => _Sell4MoreScannerState();
}

class _Sell4MoreScannerState extends State<Sell4MoreScanner> {
  Uint8List? _processedImageBytes;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _fotografierenUndSenden() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
          _processedImageBytes = null;
        });
        await _sendeBildAnBackend(File(pickedFile.path));
      }
    } catch (e) {
      _zeigeFehler("Kamera-Fehler: $e");
    }
  }

  Future<void> _sendeBildAnBackend(File imageFile) async {
    // Tausche die IP-Adresse mit deiner echten Server-IP oder Cloud-URL aus
    final Uri url = Uri.parse('http://192.168.178'); 
    
    try {
      final http.MultipartRequest request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        final Uint8List bytes = await response.stream.toBytes();
        setState(() {
          _processedImageBytes = bytes;
          _isLoading = false;
        });
      } else {
        _zeigeFehler("Server-Fehler: Status ${response.statusCode}");
      }
    } catch (e) {
      _zeigeFehler("Keine Verbindung zum Server.");
    }
  }

  void _zeigeFehler(String text) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell4More - Live Regal Scan')),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text("KI analysiert Regal & fragt Sell4More ab...", style: TextStyle(fontSize: 16)),
                ],
              )
            : _processedImageBytes != null
                ? InteractiveViewer(
                    maxScale: 5.0,
                    child: Image.memory(_processedImageBytes!),
                  )
                : const Text('Mache ein Foto deines Bücherregals, um Preise zu sehen.', style: TextStyle(fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fotografierenUndSenden,
        label: const Text('Regal Scannen'),
        icon: const Icon(Icons.camera_alt),
        backgroundColor: Colors.green,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
