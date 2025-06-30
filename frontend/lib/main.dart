import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() => runApp(YouTubeDownloaderApp());

class YouTubeDownloaderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Downloader',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DownloadPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DownloadPage extends StatefulWidget {
  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final TextEditingController _urlController = TextEditingController();
  String _status = 'Enter YouTube URL';
  double _progress = 0;
  List<Map<String, dynamic>> _history = [];
  bool _isDownloading = false;

  Future<void> _downloadVideo(String format) async {
    if (_urlController.text.isEmpty) {
      _showToast('Please enter a YouTube URL');
      return;
    }

    setState(() {
      _status = 'Processing...';
      _progress = 0;
      _isDownloading = true;
    });

    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      final response = await http.post(
        Uri.parse('http://your-ngrok-url.ngrok-free.app/download'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': _urlController.text, 'format': format}),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() => _status = 'Preparing download...');
        
        final dio = Dio();
        final dir = await getExternalStorageDirectory();
        final savePath = '${dir?.path}/${data['filename']}';
        
        await dio.download(
          data['download_url'],
          savePath,
          onReceiveProgress: (received, total) {
            setState(() {
              _progress = received / total;
              _status = 'Downloading: ${(_progress * 100).toStringAsFixed(1)}%';
            });
          },
        );

        _showToast('Download complete!');
        setState(() {
          _status = 'Download complete!';
          _history.insert(0, {
            'title': data['title'],
            'url': _urlController.text,
            'date': DateTime.now().toString(),
            'path': savePath,
            'type': format
          });
          _isDownloading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Unknown error');
      }
    } catch (e) {
      _showToast('Error: ${e.toString()}');
      setState(() {
        _status = 'Error: ${e.toString()}';
        _isDownloading = false;
      });
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YouTube Downloader'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              // Implement history view
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'YouTube URL',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(value: _progress),
            SizedBox(height: 10),
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                color: _status.contains('Error') ? Colors.red : Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : () => _downloadVideo('mp4'),
                  icon: Icon(Icons.videocam),
                  label: Text('MP4'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : () => _downloadVideo('mp3'),
                  icon: Icon(Icons.audiotrack),
                  label: Text('MP3'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            if (_history.isNotEmpty) ...[
              Text('Download History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              ..._history.take(3).map((item) => ListTile(
                leading: Icon(item['type'] == 'mp4' ? Icons.video_file : Icons.audio_file),
                title: Text(item['title'], overflow: TextOverflow.ellipsis),
                subtitle: Text(DateTime.parse(item['date']).toLocal().toString()),
                trailing: IconButton(
                  icon: Icon(Icons.open_in_new),
                  onPressed: () {
                    // Implement file opening
                  },
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
