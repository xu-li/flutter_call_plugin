import 'package:flutter/material.dart';


import 'package:flutter/services.dart';
import 'package:flutter_call_plugin/flutter_call_plugin.dart';
import "dart:convert";

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {

  String uuid = "";

  @override
  void initState() {
    super.initState();

    FlutterCallPlugin.initialize((MethodCall call) {
      print("OnCallCallback: " + call.method + ", arguments: " + jsonEncode(call.arguments));

      if (call.method == "onCallAnswered") {
        setState(() {
          uuid = call.arguments['uuid'];
        });
      }
    }).then((result) {
      print("Flutter Call Plugin has been initialized!");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("UUID: $uuid"),
              const SizedBox(height: 30),
              RaisedButton(
                child: Text("Make an outgoing call"),
                onPressed: () {
                  FlutterCallPlugin.makeCall("Xu Li").then((uuid) {
                    setState(() {
                      this.uuid = uuid;
                    });
                  });
                },
              ),
              const SizedBox(height: 30),
              RaisedButton(
                child: Text("End a call"),
                onPressed: uuid.length == 0 ? null : () {
                  FlutterCallPlugin.endCall(uuid).then((result) {
                    setState(() {
                      this.uuid = "";
                    });
                  });
                },
              ),
              const SizedBox(height: 30),
              RaisedButton(
                child: Text("Receive an incoming call"),
                onPressed: () {
                  FlutterCallPlugin.reportIncomingCall("Xu Li");
                },
              ),
            ],
          )
        ),
      ),
    );
  }
}
