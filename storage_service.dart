import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadImage(File file, {String folder = 'images'}) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('$folder/$fileName');
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadVideo(File file, {String folder = 'videos'}) async {
    final fileName = '${_uuid.v4()}.mp4';
    final ref = _storage.ref().child('$folder/$fileName');
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
