import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

VoidCallback originalSemanticsListener;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Disconnects semantics listener for testing purposes.
  originalSemanticsListener = ui.window.onSemanticsEnabledChanged;
  ui.window.onSemanticsEnabledChanged = null;
  RendererBinding.instance.setSemanticsEnabled(false);
  // If the test passes, LifeCycleSpy will rewire the semantics listener back.
  runApp(const LifeCycleSpy());
}

/// A Test widget that spies on app life cycle changes.
///
/// It will collect the AppLifecycleState sequence during its lifetime, and it
/// will rewire semantics harness if the sequence it receives matches the
/// expected list.
///
/// Rewiring semantics is a signal to native IOS test that the test has passed.
class LifeCycleSpy extends StatefulWidget {
  const LifeCycleSpy();

  @override
  _LifeCycleSpyState createState() => _LifeCycleSpyState();
}

class _LifeCycleSpyState extends State<LifeCycleSpy> with WidgetsBindingObserver {
  final List<AppLifecycleState> _expectedLifeCycleSequence = <AppLifecycleState>[
    AppLifecycleState.detached,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ];
  List<AppLifecycleState> _actualLifeCycleSequence;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _actualLifeCycleSequence =  <AppLifecycleState>[
      SchedulerBinding.instance.lifecycleState
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _actualLifeCycleSequence = List<AppLifecycleState>.from(_actualLifeCycleSequence);
      _actualLifeCycleSequence.add(state);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (const ListEquality<AppLifecycleState>().equals(_actualLifeCycleSequence, _expectedLifeCycleSequence)) {
      // Rewires the semantics harness if test passes.
      RendererBinding.instance.setSemanticsEnabled(true);
      ui.window.onSemanticsEnabledChanged = originalSemanticsListener;
    }
    return const MaterialApp(
      title: 'Flutter View',
      home: Text('test'),
    );
  }
}
