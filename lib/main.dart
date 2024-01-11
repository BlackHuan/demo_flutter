// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Center(
        // child: Text('Hello World1!'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles();
              
                    if (result != null) {
                      File file = File(result.files.single.path!);
              
                      Stream<String> lines = file.openRead().transform(utf8.decoder).transform(const LineSplitter());
                      try {
                        await for (var line in lines) {
                          print('$line: ${line.length} characters');
                        }
                        print('File is now closed.');
                      } catch (e) {
                        print('Error: $e');
                      }
                    } else {
                      // User canceled the picker
                    }
                  },
                  child: const Text('选择文件')),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () async {
                    String? outputFile = await FilePicker.platform.saveFile(
                      dialogTitle: 'Please select an output file:',
                      fileName: 'output-file.pdf',
                    );

                    if (outputFile == null) {
                      // User canceled the picker
                    } else {
                      var file = File(outputFile);
                      var sink = file.openWrite();
                      sink.write('FILE ACCESSED ${DateTime.now()}\n');

                      // Close the IOSink to free system resources.
                      sink.close();
                    }
                  },
                  child: const Text('保存文件')),
            ),
          ],
        ),
      )),
    );
  }
}
