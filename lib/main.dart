// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:process/process.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  static const platform = MethodChannel('samples.flutter.dev/battery');
  final DynamicLibrary nativeAddLib = DynamicLibrary.process();

  String _batteryLevel = 'Unknown battery level.';
  
  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final result = await platform.invokeMethod<int>('getBatteryLevel');
      batteryLevel = 'Battery level at $result % .';
    } on MissingPluginException catch (_) {
      batteryLevel = "Failed to get plugin.";
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Center(
        // child: Text('Hello World1!'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles();

                        if (result != null) {
                          File file = File(result.files.single.path!);

                          Stream<String> lines = file
                              .openRead()
                              .transform(utf8.decoder)
                              .transform(const LineSplitter());
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
                      child: const Text('File Read')),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: () async {
                        // Find the correct local path: https://docs.flutter.dev/cookbook/persistence/reading-writing-files#1-find-the-correct-local-path

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
                      child: const Text('File Save')),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () async {
                    var p = ProcessWrapper(await Process.start('ls', ['-l']));
                    print(p.pid);
                    await for (var line in p.stdout
                        .transform(utf8.decoder)
                        .transform(const LineSplitter())) {
                      print(line);
                    }
                  },
                  child: const Text('Process')),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () async {
                    void runInIsolate(SendPort sendPort) {
                      sendPort.send('Hello from Isolate!');
                    }

                    final receivePort = ReceivePort();
                    final isolate =
                        await Isolate.spawn(runInIsolate, receivePort.sendPort);

                    receivePort.listen((message) {
                      print('Message from Isolate: $message');
                      receivePort.close();
                      isolate.kill();
                    });

                    int addNumbers(Map<String, int> data) {
                      final a = data['a']!;
                      final b = data['b']!;
                      return a + b;
                    }

                    final result = await compute(addNumbers, {'a': 3, 'b': 4});
                    print('Result: $result');
                  },
                  child: const Text('Isolate')),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ElevatedButton(
                          onPressed: _getBatteryLevel,
                          child: const Text('Platform Channels')),
                      Text(_batteryLevel),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: () async {
                        final int Function() tmp = nativeAddLib
                          .lookup<NativeFunction<Int32 Function()>>('avcodec_configuration')
                          .asFunction();
                        print("1");
                        tmp();
                        print("2");
                      }, child: const Text('FFI')),
                ),
              ],
            ),
          ],
        ),
      )),
    );
  }
}
