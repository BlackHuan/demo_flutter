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
              
                      print(file);
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
              
                    print(outputFile);
              
                    if (outputFile == null) {
                      // User canceled the picker
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
