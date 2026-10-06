import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MaterialApp(
  theme: ThemeData.dark(), // Modernes Dark-Theme
  home: Sell4MoreScanner(),
));

class Sell4MoreScanner extends StatefulWidget {
  @override
  _Sell4MoreScannerState createState() => _Sell4MoreScannerState();
}

class _Sell4MoreScannerState extends State<Sell4MoreScanner> {
  Uint8List? _processedImageBytes;
  bool _isLoading = false;
  final _picker = ImagePicker();

  Future<void> _fotografierenUndSenden() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    
    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
        _processedImageBytes = null;
      });
      
      _sendeBildAnBackend(File(pickedFile.path));
    }
  }

  Future<void> _sendeBildAnBackend(File imageFile) async {
    // Tausche die IP-Adresse mit der Server-IP aus deinem Netzwerk oder Cloud aus
    var url = Uri.parse('http://192.168.178.X:8000/scan-regal/'); 
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var bytes = await response.stream.toBytes();
        setState(() {
          _processedImageBytes = bytes;
          _isLoading = false;
        });
      } else {
        _zeigeFehler("Server antwortete mit Fehlercode: ${response.statusCode}");
      }
    } catch (e) {
      _zeigeFehler("Verbindung zum Sell4More-Backend fehlgeschlagen.");
    }
  }

  void _zeigeFehler(String text) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sell4More - Live Regal Scan')),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text("KI analysiert Regal & fragt Sell4More ab...", style: TextStyle(fontSize: 16)),
                ],
              )
            : _processedImageBytes != null
                ? InteractiveViewer( // Ermöglicht dem Nutzer in das fertige Bild hineinzuzoomen
                    maxScale: 5.0,
                    child: Image.memory(_processedImageBytes!),
                  )
                : Text('Mache ein Foto deines Bücherregals, um Preise zu sehen.', style: TextStyle(fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fotografierenUndSenden,
        label: Text('Regal Scannen'),
        icon: Icon(Icons.camera_alt),
        backgroundColor: Colors.green,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
