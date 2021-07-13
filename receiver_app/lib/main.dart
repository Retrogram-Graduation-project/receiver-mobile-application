import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:photo_view/photo_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Receiver device'),
        ),
        body: Body(),
      ),
    );
  }
}

class Body extends StatefulWidget {
  @override
  _MyBodyState createState() => _MyBodyState();
}

class _MyBodyState extends State<Body> {
  final String userName = "Retro the first";
  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;
  Map<String, ConnectionInfo> endpointMap = Map();

  String? tempFileUri; //reference to the file currently being transferred
  Map<int, String> map =
      Map(); //store filename mapped to corresponding payloadId

  void discover() async {
    if (await Nearby().checkLocationPermission())
      Nearby().askLocationPermission();
    bool a = false;
    while (!a) {
      try {
        a = await Nearby().startAdvertising(
          userName,
          strategy,
          onConnectionInitiated: onConnectionInit,
          onConnectionResult: (id, status) {
            showSnackbar(status);
          },
          onDisconnected: (id) {
            showSnackbar(
                "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
            setState(() {
              endpointMap.remove(id);
            });
            print("Stopping advertising");
            Nearby().stopAdvertising();
            discover();
          },
        );
        if (a) showSnackbar("START ADVERTISING");
      } catch (exception) {
        showSnackbar(exception);
      }
    }
  }

  @override
  void initState() {
    controller = PhotoViewController(initialScale: 0.1);
    discover();
    super.initState();
  }

  double min = pi * -2;
  double max = pi * 2;

  double minScale = 0.03;
  double defScale = 0.1;
  double maxScale = 0.6;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            Center(
              child: Text(endpointMap.isNotEmpty
                  ? "Sender connected"
                  : "Sender not connected"),
            ),
            ElevatedButton(
              child: Text("Disconnect sender"),
              onPressed: () async {
                await Nearby().stopAllEndpoints();
                await Nearby().stopAdvertising();
                setState(() {
                  endpointMap.clear();
                });
                discover();
              },
            ),
            Divider(),
            SizedBox(height: 20),
            if (txt != null)
              Center(
                child: Text(txt!),
              ),
            if (filePath != null)
              Container(
                width: 400,
                height: 500,
                child: PhotoView(
                  imageProvider: FileImage(File(filePath!)),
                  controller: controller,
                  enableRotation: true,
                  initialScale: minScale * 1.5,
                  minScale: minScale,
                  maxScale: maxScale,
                ),
              ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void showSnackbar(dynamic a) {
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text(a.toString()),
    // ));
  }

  Future<bool> moveFile(String uri, String fileName) async {
    String parentDir = (await getExternalStorageDirectory())!.absolute.path;
    final b =
        await Nearby().copyFileAndDeleteOriginal(uri, '$parentDir/$fileName');

    setState(() {
      filePath = "$parentDir/$fileName";
      txt = null;
      print("##### $filePath");
    });
    showSnackbar("Moved file:" + b.toString());
    return b;
  }

  String? txt;
  String? filePath;
  double? scale;
  double? rotation;
  PhotoViewControllerBase? controller;

  /// Called upon Connection request (on both devices)
  /// Both need to accept connection to start sending/receiving
  void onConnectionInit(String id, ConnectionInfo info) {
    setState(() {
      endpointMap[id] = info;
    });
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String str = String.fromCharCodes(payload.bytes!);
          showSnackbar(endid + ": " + str);

          String checker = "";
          try {
            checker = str.substring(0, 4);
            print(checker);
            setState(() {
              if (checker == "s45:")
                controller!.scale = double.parse(str.split(":")[1]);
              else if (checker == "r45:")
                controller!.rotation = double.parse(str.split(":")[1]);
              else {
                txt = str;
                filePath = null;
                controller = PhotoViewController(initialScale: 0.1);
              }
            });
          } catch (e) {
            setState(() {
              txt = str;
              filePath = null;
              controller = PhotoViewController(initialScale: 0.1);
            });
          }

          if (str.contains(':') && checker != "s45:" && checker != "r45:") {
            // used for file payload as file payload is mapped as
            // payloadId:filename
            int payloadId = int.parse(str.split(':')[0]);
            String fileName = (str.split(':')[1]);

            if (map.containsKey(payloadId)) {
              if (tempFileUri != null) {
                moveFile(tempFileUri!, fileName);
              } else {
                showSnackbar("File doesn't exist");
              }
            } else {
              //add to map if not already
              map[payloadId] = fileName;
            }
          }
        } else if (payload.type == PayloadType.FILE) {
          showSnackbar(endid + ": File transfer started");
          tempFileUri = payload.uri;
        }
      },
      onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
        if (payloadTransferUpdate.status == PayloadStatus.IN_PROGRESS) {
          print(payloadTransferUpdate.bytesTransferred);
        } else if (payloadTransferUpdate.status == PayloadStatus.FAILURE) {
          print("failed");
          showSnackbar(endid + ": FAILED to transfer file");
        } else if (payloadTransferUpdate.status == PayloadStatus.SUCCESS) {
          showSnackbar(
              "$endid success, total bytes = ${payloadTransferUpdate.totalBytes}");

          if (map.containsKey(payloadTransferUpdate.id)) {
            //rename the file now
            String name = map[payloadTransferUpdate.id]!;
            moveFile(tempFileUri!, name);
          } else {
            //bytes not received till yet
            map[payloadTransferUpdate.id] = "";
          }
        }
      },
    );
  }
}
