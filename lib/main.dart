// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:process/process.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

class Dog {
  final int id;
  final String name;
  final int age;

  const Dog({
    required this.id,
    required this.name,
    required this.age,
  });

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Dog{id: $id, name: $name, age: $age}';
  }
}

void main() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();
  // Open the database and store the reference.
  final database = openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'doggie_database.db'),
    // When the database is first created, create a table to store dogs.
    onCreate: (db, version) {
      // Run the CREATE TABLE statement on the database.
      return db.execute(
        'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
      );
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );

  // Define a function that inserts dogs into the database
  Future<void> insertDog(Dog dog) async {
    // Get a reference to the database.
    final db = await database;

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Create a Dog and add it to the dogs table
  var fido = const Dog(
    id: 0,
    name: 'Fido',
    age: 35,
  );

  await insertDog(fido);

  // A method that retrieves all the dogs from the dogs table.
  Future<List<Dog>> dogs() async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('dogs');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return Dog(
        id: maps[i]['id'] as int,
        name: maps[i]['name'] as String,
        age: maps[i]['age'] as int,
      );
    });
  }

  // Now, use the method above to retrieve all the dogs.
  print(await dogs()); // Prints a list that include Fido.

  Future<void> updateDog(Dog dog) async {
    // Get a reference to the database.
    final db = await database;

    // Update the given Dog.
    await db.update(
      'dogs',
      dog.toMap(),
      // Ensure that the Dog has a matching id.
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [dog.id],
    );
  }

  // Update Fido's age and save it to the database.
  fido = Dog(
    id: fido.id,
    name: fido.name,
    age: fido.age + 7,
  );
  await updateDog(fido);

  // Print the updated results.
  print(await dogs()); // Prints Fido with age 42.

  Future<void> deleteDog(int id) async {
    // Get a reference to the database.
    final db = await database;

    // Remove the Dog from the database.
    await db.delete(
      'dogs',
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  runApp(const MainApp());
}

class ErrorInfo {
  final int code;
  final String msg;

  const ErrorInfo({required this.code, required this.msg});

  factory ErrorInfo.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'code': int code,
        'msg': String msg,
      } =>
        ErrorInfo(
          code: code,
          msg: msg,
        ),
      _ => throw const FormatException('Failed to load ErrorInfo.'),
    };
  }
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
                            .lookup<NativeFunction<Int32 Function()>>(
                                'avcodec_configuration')
                            .asFunction();
                        print("1");
                        tmp();
                        print("2");

                        // final dylib = DynamicLibrary.open('/usr/local/Cellar/ffmpeg/6.1.1_2/lib/libavcodec.dylib');
                        // final void Function() tmp = dylib
                        //   .lookup<NativeFunction<Void Function()>>('avcodec_configuration')
                        //   .asFunction();
                        // print("1");
                        // tmp();
                        // print("2");
                      },
                      child: const Text('FFI')),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        final http.Response tmp = await http.post(
                          Uri.parse(
                              'https://127.0.0.1:8000/login'),
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                          },
                          body: jsonEncode(<String, String>{
                            'username': 'black.wang',
                            'password': '123',
                          }),
                        );


                      },
                      child: const Text('HTTP')),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}
