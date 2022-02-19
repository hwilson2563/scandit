/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2021- Scandit AG. All rights reserved.
 */

import 'package:IdCaptureExtendedSample/home/bloc/id_capture_bloc.dart';
import 'package:IdCaptureExtendedSample/home/model/Id_capture_mode.dart';
import 'package:IdCaptureExtendedSample/home/model/capture_event.dart';
import 'package:IdCaptureExtendedSample/route/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class IdCaptureView extends StatefulWidget {
  final String title;

  IdCaptureView(this.title, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _IdCaptureViewState(IdCaptureBloc());
  }
}

class _IdCaptureViewState extends State<IdCaptureView> with WidgetsBindingObserver {
  final IdCaptureBloc _bloc;

  _IdCaptureViewState(this._bloc);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance?.addObserver(this);

    _bloc.idCaptureController.listen((event) {
      if (event.content is AskBackScan) {
        showAskBackScanDialog(context);
        return;
      }

      // Display result
      Navigator.pushNamed(context, ICRoutes.Result.routeName, arguments: event.content)
          .then((value) => _bloc.enableIdCapture());
    });

    _checkPermission();
  }

  Future showAskBackScanDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Skip"),
      onPressed: () {
        Navigator.of(context).pop();
        _bloc.skipBackside();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Scan"),
      onPressed: () {
        Navigator.of(context).pop();
        _bloc.continueBackside();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Back of Card"),
      content: Text("This document has additional data in the visual inspection zone on the back of the card?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    } else if (state == AppLifecycleState.paused) {
      _bloc.switchCameraOff();
    }
  }

  @override
  void dispose() {
    _bloc.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [],
      ),
      body: SafeArea(child: _bloc.dataCaptureView),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bloc.currentModeIndex,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/ic_barcode.png',
              scale: 1.5,
            ),
            label: IdCaptureMode.barcode.name,
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/ic_mrz.png',
              scale: 1.5,
            ),
            label: IdCaptureMode.mrz.name,
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/ic_viz.png',
              scale: 1.5,
            ),
            label: IdCaptureMode.viz.name,
          )
        ],
        onTap: (int index) {
          setState(() {
            _bloc.currentModeIndex = index;
          });
        },
        selectedIconTheme: IconThemeData(opacity: 0.0, size: 0),
        unselectedIconTheme: IconThemeData(opacity: 0.0, size: 0),
        backgroundColor: Colors.black,
        unselectedItemColor: Colors.white,
      ),
    );
  }

  void _checkPermission() async {
    // Check camera permission is granted before switching the camera on
    var permissionsResult = await Permission.camera.request();
    if (permissionsResult.isGranted) {
      // Switch camera on to start streaming frames.
      // The camera is started asynchronously and will take some time to completely turn on.
      _bloc.switchCameraOn();
      _bloc.enableIdCapture();
    }
  }
}