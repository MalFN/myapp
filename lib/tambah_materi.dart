import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

class TambahMateri extends StatefulWidget {
  final String? documentId;

  const TambahMateri({this.documentId, super.key});

  @override
  _TambahMateriState createState() => _TambahMateriState();
}

class _TambahMateriState extends State<TambahMateri> {
  final TextEditingController kodeController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  String? _videoUrl;
  bool _isUploading = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.documentId != null) {
      _fetchMateriData();
    }
  }

  Future<void> _fetchMateriData() async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('materi')
        .doc(widget.documentId)
        .get();
    
    if (documentSnapshot.exists) {
      Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
      kodeController.text = data['kode'];
      namaController.text = data['nama'];
      deskripsiController.text = data['deskripsi'];
      _videoUrl = data['url'];
      if (_videoUrl != null) {
        _initializeVideoPlayer(_videoUrl!);
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    kodeController.dispose();
    namaController.dispose();
    deskripsiController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      await _uploadVideo(file);
    } else {
      // User canceled the picker
    }
  }

  Future<void> _uploadVideo(PlatformFile file) async {
    setState(() {
      _isUploading = true;
    });

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('videos/${file.name}');
    UploadTask uploadTask = ref.putFile(File(file.path!));

    await uploadTask.whenComplete(() async {
      _videoUrl = await ref.getDownloadURL();
      setState(() {
        _isUploading = false;
        _initializeVideoPlayer(_videoUrl!);
      });
    }).catchError((error) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunggah video: $error')));
    });
  }

  void _initializeVideoPlayer(String videoUrl) {
    _videoController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
      });
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      DocumentReference documentReference;
      if (widget.documentId != null) {
        documentReference = FirebaseFirestore.instance.collection('materi').doc(widget.documentId);
      } else {
        documentReference = FirebaseFirestore.instance.collection('materi').doc(kodeController.text);
      }

      // Ambil nilai dari TextEditingController
      Map<String, dynamic> mtr = {
        'kode': kodeController.text,
        'nama': namaController.text,
        'deskripsi': deskripsiController.text,
        'url': _videoUrl,
      };

      // Simpan ke Firestore
      try {
        await documentReference.set(mtr);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan')));
        Navigator.pop(context); // Kembali ke halaman sebelumnya (home)
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
      }
    }
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Materi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: kodeController,
                decoration: const InputDecoration(labelText: 'Kode'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kode tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickVideo,
                child: const Text('Pilih Video'),
              ),
              _isUploading ? const CircularProgressIndicator() : Container(),
              _videoUrl != null && _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : Container(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
