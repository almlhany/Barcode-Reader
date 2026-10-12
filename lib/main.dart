import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// --- الساعة الرقمية ---
class LiveClock extends StatefulWidget {
  const LiveClock({super.key});
  @override State<LiveClock> createState() => _LiveClockState();
}
class _LiveClockState extends State<LiveClock> {
  late Timer t; DateTime now = DateTime.now();
  @override void initState(){ super.initState(); t = Timer.periodic(Duration(seconds:1), (_)=>setState(()=>now=DateTime.now())); }
  @override void dispose(){ t.cancel(); super.dispose(); }
  @override Widget build(BuildContext context){
    String p(int n)=>n.toString().padLeft(2,'0');
    return Container(
      padding: EdgeInsets.symmetric(horizontal:14, vertical:8),
      decoration: BoxDecoration(color: Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12)),
      child: Text("${p(now.hour)}:${p(now.minute)}:${p(now.second)}  ${now.day}/${now.month}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    );
  }
}

// --- قاعدة البيانات المحلية (بدون shared_preferences) ---
class ScanDB {
  static final List<Map<String,dynamic>> _data = [];
  static void add(String code){
    _data.insert(0, {"code":code, "time":DateTime.now()});
    if(_data.length>100) _data.removeLast();
  }
  static List<Map<String,dynamic>> getAll() => _data;
  static void clear() => _data.clear();
}

void main()=>runApp(MaterialApp(debugShowCheckedModeBanner:false, home: QRDBApp()));

class QRDBApp extends StatefulWidget{ @override State<QRDBApp> createState()=>_QRDBAppState(); }
class _QRDBAppState extends State<QRDBApp>{
  String last = "لم يتم المسح بعد";
  final controller = MobileScannerController();
  @override Widget build(BuildContext context)=>Scaffold(
    appBar: AppBar(title: Text("QR + قاعدة بيانات + ساعة"), actions:[Padding(padding: EdgeInsets.all(8), child: LiveClock())]),
    body: Column(children:[
      SizedBox(height:300, child: MobileScanner(controller: controller, onDetect:(c){
        final v = c.barcodes.first.rawValue;
        if(v!=null){ setState(()=>last=v); ScanDB.add(v); }
      })),
      SizedBox(height:12), LiveClock(), SizedBox(height:12),
      Text("آخر مسح: $last", style:TextStyle(fontWeight:FontWeight.bold)),
      Expanded(child: ListView(children: ScanDB.getAll().map((e)=>ListTile(title:Text(e["code"]), subtitle:Text("${e["time"].hour}:${e["time"].minute}:${e["time"].second}"))).toList())),
      FilledButton(onPressed:()=>setState(()=>ScanDB.clear()), child:Text("مسح القاعدة"))
    ]),
  );
}