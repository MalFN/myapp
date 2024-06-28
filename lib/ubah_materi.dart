import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class UbahMateri extends StatefulWidget {
  final String kode;

  const UbahMateri({super.key, required this.kode});

  @override
  _UbahMateriState createState() => _UbahMateriState();
}

class _UbahMateriState extends State<UbahMateri> {
  final TextEditingController kodeController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  String? _videoUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadMateriData();
  }

  Future<void> _loadMateriData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('materi')
        .doc(widget.kode)
        .get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      kodeController.text = data['kode'];
      namaController.text = data['nama'];
      deskripsiController.text = data['deskripsi'];
      _videoUrl = data['url'];
    }
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
      });
    }).catchError((error) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengunggah video: $error')));
    });
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      DocumentReference documentReference =
          FirebaseFirestore.instance.collection('materi').doc(kodeController.text);

      Map<String, dynamic> mtr = {
        'kode': kodeController.text,
        'nama': namaController.text,
        'deskripsi': deskripsiController.text,
        'url': _videoUrl,
      };

      try {
        await documentReference.update(mtr);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Data berhasil diperbarui')));
        Navigator.pop(context); // Kembali ke halaman sebelumnya (home)
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memperbarui data: $e')));
      }
    }
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Materi'),
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
                readOnly: true,
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
              _isUploading
                  ? const CircularProgressIndicator()
                  : _videoUrl != null
                      ? const Text('Video berhasil diunggah')
                      : Container(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
