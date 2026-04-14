import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../storyteller/domain/entities/storyteller.dart';

class FileImportEntry {
  FileImportEntry({
    required this.id,
    required this.path,
    required this.fileName,
    required this.sizeBytes,
    required this.format,
    required this.durationSeconds,
    this.webBytes,
    this.genreId,
    this.subcategoryId,
    this.registerId,
    this.storyteller,
    String? initialTitle,
    String? initialDescription,
  }) : titleController = TextEditingController(text: initialTitle ?? ''),
       descriptionController = TextEditingController(
         text: initialDescription ?? '',
       );

  final String id;
  final String path;
  final String fileName;
  final int sizeBytes;
  final String format;
  final double durationSeconds;
  final Uint8List? webBytes;

  String? genreId;
  String? subcategoryId;
  String? registerId;
  Storyteller? storyteller;

  final TextEditingController titleController;
  final TextEditingController descriptionController;

  String? get storytellerId => storyteller?.id;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}
