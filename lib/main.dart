import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(MyLocalMusicApp());
}

class MyLocalMusicApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'x-audio Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Color(0xFF1E1E2C), // Couleur de fond sombre
        fontFamily: 'RobotoMono', // Police moderne
      ),
      home: LocalMusicPlayerScreen(),
      routes: {
        '/audioList': (context) => AudioListScreen(),
      },
    );
  }
}

class LocalMusicPlayerScreen extends StatefulWidget {
  @override
  _LocalMusicPlayerScreenState createState() => _LocalMusicPlayerScreenState();
}

class _LocalMusicPlayerScreenState extends State<LocalMusicPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  String? filePath;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _requestStoragePermission();
  }

  Future<void> _requestStoragePermission() async {
    if (!await Permission.storage.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Accès au stockage requis pour lire des fichiers audio")),
      );
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null) {
      setState(() {
        filePath = result.files.single.path;
      });
      _playAudio(filePath!);
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.setFilePath(path);
      _audioPlayer.play();
      setState(() {
        isPlaying = true;
      });
    } catch (e) {
      print("Erreur de lecture du fichier audio: $e");
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("x-audio"),
        backgroundColor: Colors.indigo,
        elevation: 10,
        actions: [
          IconButton(
            icon: Icon(Icons.library_music, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.pushNamed(context, '/audioList');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              filePath != null
                  ? " : ${filePath!.split('/').last}"
                  : "Aucun fichier sélectionné",
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            GestureDetector(
              onTap: isPlaying
                  ? _pauseAudio
                  : (filePath != null ? () => _playAudio(filePath!) : null),
              child: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                size: 120,
                color: Colors.cyanAccent,
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  label: "Arrêter",
                  color: Colors.redAccent,
                  onPressed: _stopAudio,
                ),
                SizedBox(width: 20),
                _buildControlButton(
                  label: "Sélectionner",
                  color: Colors.blueAccent,
                  onPressed: _pickFile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
      {required String label,
      required Color color,
      required VoidCallback? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shadowColor: color.withOpacity(0.5),
        elevation: 15,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
            fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AudioListScreen extends StatefulWidget {
  @override
  _AudioListScreenState createState() => _AudioListScreenState();
}

class _AudioListScreenState extends State<AudioListScreen> {
  List<File> audioFiles = [];

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
  }

  Future<void> _loadAudioFiles() async {
    if (await Permission.storage.request().isGranted) {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        setState(() {
          audioFiles = _listAudioFiles(directory);
        });
      }
    }
  }

  List<File> _listAudioFiles(Directory directory) {
    List<File> files = [];
    directory.listSync(recursive: true).forEach((entity) {
      if (entity is File &&
          (entity.path.endsWith(".mp3") ||
              entity.path.endsWith(".wav") ||
              entity.path.endsWith(".m4a"))) {
        files.add(entity);
      }
    });
    return files;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Liste des fichiers audio"),
        backgroundColor: Colors.indigo,
      ),
      body: audioFiles.isEmpty
          ? Center(
              child: Text(
                "Aucun fichier audio trouvé.",
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
            )
          : ListView.builder(
              itemCount: audioFiles.length,
              itemBuilder: (context, index) {
                final file = audioFiles[index];
                return Card(
                  color: Colors.black54,
                  child: ListTile(
                    title: Text(
                      file.path.split('/').last,
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                    trailing: Icon(Icons.play_arrow, color: Colors.cyanAccent),
                    onTap: () {
                      Navigator.pop(context, file.path);
                    },
                  ),
                );
              },
            ),
    );
  }
}
