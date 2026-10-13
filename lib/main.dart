import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
void main()=> runApp(App());
class App extends StatelessWidget{ @override Widget build(BuildContext c)=> MaterialApp(debugShowCheckedModeBanner:false, theme:ThemeData.dark(), home:AlarmApp());}

// ===== انواع النغمات =====
class Tone{ String name; IconData icon; Tone(this.name,this.icon);}
List<Tone> tones=[
  Tone("افتراضي", Icons.music_note),
  Tone("اذان الفجر", Icons.mosque),
  Tone("رقمي حاد", Icons.surround_sound),
  Tone("كلاسيك", Icons.album),
  Tone("انذار قوي", Icons.warning_amber_rounded),
  Tone("عصافير", Icons.eco),
];

class MyAlarm{
  int id; int hour; int minute; String label; bool enabled; Tone tone; List<bool> days; bool vibrate;
  MyAlarm({required this.id, required this.hour, required this.minute, this.label="منبه", this.enabled=true, required this.tone, List<bool>? days, this.vibrate=true}):days=days?? List.filled(7,true);
  String get timeStr{ String p(int v)=>v.toString().padLeft(2,'0'); String am=hour>=12?"م":"ص"; int h=hour>12?hour-12: (hour==0?12:hour); return "${p(h)}:${p(minute)} $am"; }
  String get time24{ String p(int v)=>v.toString().padLeft(2,'0'); return "${p(hour)}:${p(minute)}"; }
  String get daysStr{
    if(days.every((d)=>d)) return "كل يوم";
    List<String> n=["ث","ن","ث","ر","خ","ج","س"]; List<String> s=[];
    for(int i=0;i<7;i++) if(days[i]) s.add(n[i]);
    return s.isEmpty? "مرة واحدة" : s.join("، ");
  }
}

class AlarmApp extends StatefulWidget{ @override State<AlarmApp> createState()=>_A();}
class _A extends State<AlarmApp>{
  List<MyAlarm> alarms=[
    MyAlarm(id:1, hour:5, minute:0, label:"صلاة الفجر", tone:tones[1], days:[false,true,true,true,true,true,false], vibrate:true),
    MyAlarm(id:2, hour:7, minute:0, label:"الدوام", tone:tones[0]),
  ];
  late Timer clockTimer;
  DateTime now=DateTime.now();
  bool isRinging=false;

  @override void initState(){
    super.initState();
    clockTimer=Timer.periodic(Duration(seconds:1),(_){
      setState(()=> now=DateTime.now());
      _check();
    });
  }
  @override void dispose(){ clockTimer.cancel(); super.dispose();}
  void _check(){
    if(isRinging) return;
    for(var a in alarms){
      if(!a.enabled) continue;
      if(now.hour==a.hour && now.minute==a.minute && now.second==0){
        int w=now.weekday-1; // 0=الاثنين
        if(!a.days[w] &&!a.days.every((d)=>d==false)) continue; // لو محدد ايام
        _ring(a); break;
      }
    }
  }
  void _ring(MyAlarm a){
    setState(()=> isRinging=true);
    showDialog(context:context, barrierDismissible:false, builder:(_)=> _RingScreen(alarm:a, onStop:(){ Navigator.pop(context); setState(()=> isRinging=false);}, onSnooze:(){
      Navigator.pop(context); setState(()=> isRinging=false);
      var snooze=now.add(Duration(minutes:5));
      setState(()=> alarms.add(MyAlarm(id:DateTime.now().millisecondsSinceEpoch, hour:snooze.hour, minute:snooze.minute, label:"غفوة - ${a.label}", tone:a.tone, days:List.filled(7,true))));
    }));
  }

  void _addEdit({MyAlarm? edit}){
    TimeOfDay picked=edit!=null? TimeOfDay(hour:edit.hour, minute:edit.minute) : TimeOfDay.now();
    String label=edit?.label??""; Tone tone=edit?.tone?? tones[0]; List<bool> days=edit!=null? List.from(edit.days) : List.filled(7,true); bool vibrate=edit?.vibrate?? true;
    showModalBottomSheet(context:context, isScrollControlled:true, backgroundColor:Color(0xFF1A1A1A), builder:(_)=> StatefulBuilder(builder:(c,set){
      return Padding(padding:EdgeInsets.only(bottom:MediaQuery.of(context).viewInsets.bottom, left:16,right:16,top:16), child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min, children:[
        Text(edit==null?"اضافة منبه":"تعديل المنبه", style:TextStyle(fontWeight:FontWeight.bold, fontSize:18)), SizedBox(height:16),
        GestureDetector(onTap:() async { var t=await showTimePicker(context:context, initialTime:picked); if(t!=null) set(()=> picked=t);}, child:Container(padding:EdgeInsets.all(18), decoration:BoxDecoration(color:Colors.white10, borderRadius:BorderRadius.circular(16)), child:Row(mainAxisAlignment:MainAxisAlignment.center, children:[Icon(Icons.access_time, size:28), SizedBox(width:10), Text(picked.format(context), style:TextStyle(fontSize:30, fontWeight:FontWeight.bold))]))),
        SizedBox(height:12),
        TextField(controller:TextEditingController(text:label), onChanged:(v)=> label=v, decoration:InputDecoration(labelText:"اسم المنبه", filled:true, fillColor:Colors.white10, border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide.none))),
        SizedBox(height:12),
        // اختيار النغمة
        Align(alignment:Alignment.centerRight, child:Text("النغمة:", style:TextStyle(fontWeight:FontWeight.bold))), SizedBox(height:6),
        SizedBox(height:50, child:ListView.builder(scrollDirection:Axis.horizontal, itemCount:tones.length, itemBuilder:(_,i)=> GestureDetector(onTap:(){ set(()=> tone=tones[i]); HapticFeedback.mediumImpact();}, child:Container(margin:EdgeInsets.only(left:8), padding:EdgeInsets.symmetric(horizontal:14), decoration:BoxDecoration(color: tone==tones[i]? Color(0xFFFE2C55) : Colors.white10, borderRadius:BorderRadius.circular(12)), child:Row(children:[Icon(tones[i].icon,size:18), SizedBox(width:6), Text(tones[i].name, style:TextStyle(fontSize:12))]))))),
        SizedBox(height:12),
        // تكرار ايام الاسبوع
        Align(alignment:Alignment.centerRight, child:Text("تكرار:", style:TextStyle(fontWeight:FontWeight.bold))), SizedBox(height:6),
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children: List.generate(7,(i){
          List<String> d=["إ","ث","أ","خ","ج","س","أ"]; // اختصار
          List<String> full=["الاثنين","الثلاثاء","الاربعاء","الخميس","الجمعة","السبت","الاحد"];
          return GestureDetector(onTap:()=> set(()=> days[i]=!days[i]), child:Column(children:[Container(width:38,height:38, decoration:BoxDecoration(color:days[i]? Color(0xFFFE2C55) : Colors.white10, shape:BoxShape.circle), child:Center(child:Text(d[i], style:TextStyle(fontWeight:FontWeight.bold, fontSize:12)))), SizedBox(height:2), Text(full[i].substring(0,2), style:TextStyle(fontSize:9, color:Colors.white54))]));
        })),
        SizedBox(height:12),
        // اهتزاز قوي
        SwitchListTile(value:vibrate, activeColor:Color(0xFFFE2C55), title:Text("اهتزاز قوي"), subtitle:Text("Vibration", style:TextStyle(fontSize:10, color:Colors.white54)), secondary:Icon(Icons.vibration), onChanged:(v)=> set(()=> vibrate=v)),
        SizedBox(height:12),
        SizedBox(width:double.infinity, child:FilmedButton(label: edit==null?"حفظ المنبه":"تحديث", onPressed:(){
          var na=MyAlarm(id:edit?.id?? DateTime.now().millisecondsSinceEpoch, hour:picked.hour, minute:picked.minute, label:label.isEmpty?"منبه":label, tone:tone, days:days, vibrate:vibrate);
          setState(()=> { if(edit!=null) alarms.removeWhere((x)=> x.id==edit.id), alarms.add(na)});
          Navigator.pop(context);
        })),
        SizedBox(height:20),
      ])));
    }));
  }

  @override Widget build(BuildContext c){
    String p(int v)=>v.toString().padLeft(2,'0'); String am=now.hour>=12?"م":"ص"; int h=now.hour>12?now.hour-12: (now.hour==0?12:now.hour);
    return Scaffold(backgroundColor:Color(0xFF0A0A0A), appBar:AppBar(backgroundColor:Colors.black, title:Text("ساعة منبه", style:TextStyle(fontWeight:FontWeight.w900)), centerTitle:true),
      body:Column(children:[
        Container(margin:EdgeInsets.all(14), padding:EdgeInsets.all(18), decoration:BoxDecoration(color:Color(0xFF1A1A1A), borderRadius:BorderRadius.circular(20)), child:Column(children:[
          Text("${p(h)}:${p(now.minute)}:${p(now.second)} $am", style:TextStyle(fontSize:38, fontWeight:FontWeight.w900)),
          Text("${now.year}/${p(now.month)}/${p(now.day)}", style:TextStyle(color:Colors.white54, fontSize:12)),
        ])),
        Expanded(child:ListView.builder(padding:EdgeInsets.all(10), itemCount:alarms.length, itemBuilder:(_,i){
          var a=alarms[i];
          return Container(margin:EdgeInsets.only(bottom:10), decoration:BoxDecoration(color:Color(0xFF1E1E1E), borderRadius:BorderRadius.circular(16)), child:ListTile(
            onTap:()=> _addEdit(edit:a),
            leading:Icon(a.tone.icon, color:a.enabled? Color(0xFFFE2C55) : Colors.white24),
            title:Text(a.timeStr, style:TextStyle(fontSize:18, fontWeight:FontWeight.bold, color: a.enabled? Colors.white : Colors.white38)),
            subtitle:Text("${a.label} • ${a.tone.name} • ${a.daysStr} ${a.vibrate?"• اهتزاز":""}", style:TextStyle(fontSize:10, color:Colors.white60)),
            trailing:Row(mainAxisSize:MainAxisSize.min, children:[
              Switch(value:a.enabled, activeColor:Color(0xFFFE2C55), onChanged:(v)=> setState(()=> a.enabled=v)),
              IconButton(icon:Icon(Icons.delete_outline, size:20), onPressed:()=> setState(()=> alarms.removeAt(i))),
            ]),
          ));
        })),
      ]),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=> _addEdit(), backgroundColor:Color(0xFFFE2C55), icon:Icon(Icons.add_alarm), label:Text("منبه جديد")),
    );
  }
}

class _RingScreen extends StatefulWidget{ final MyAlarm alarm; final VoidCallback onStop,onSnooze; const _RingScreen({required this.alarm, required this.onStop, required this.onSnooze}); @override State<_RingScreen> createState()=>__R();}
class __R extends State<_RingScreen> with SingleTickerProviderStateMixin{
  late AnimationController anim; late Timer vibTimer;
  @override void initState(){ super.initState(); anim=AnimationController(vsync:this, duration:Duration(milliseconds:500))..repeat(reverse:true);
    vibTimer=Timer.periodic(Duration(milliseconds:700),(_){ if(widget.alarm.vibrate){ HapticFeedback.heavyImpact(); Future.delayed(Duration(milliseconds:150),()=> HapticFeedback.heavyImpact());}});
  }
  @override void dispose(){ anim.dispose(); vibTimer.cancel(); super.dispose();}
  @override Widget build(BuildContext c)=> Scaffold(backgroundColor:Color(0xFFFE2C55), body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[
    ScaleTransition(scale:Tween(begin:1.0,end:1.25).animate(anim), child:Icon(widget.alarm.tone.icon, size:90, color:Colors.white)),
    SizedBox(height:16), Text("⏰ المنبه يرن!", style:TextStyle(fontSize:28, fontWeight:FontWeight.w900, color:Colors.white)),
    SizedBox(height:8), Text(widget.alarm.label, style:TextStyle(fontSize:22, color:Colors.white, fontWeight:FontWeight.bold)),
    SizedBox(height:4), Text("${widget.alarm.time24} • ${widget.alarm.tone.name}", style:TextStyle(color:Colors.white70)),
    if(widget.alarm.vibrate) Padding(padding:EdgeInsets.only(top:6), child:Row(mainAxisAlignment:MainAxisAlignment.center, children:[Icon(Icons.vibration, color:Colors.white70, size:16), SizedBox(width:4), Text("اهتزاز قوي مفعل", style:TextStyle(color:Colors.white70, fontSize:11))])),
    SizedBox(height:40),
    Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly, children:[
      FilledButton(onPressed:widget.onSnooze, style: FilledButton.styleFrom(backgroundColor:Colors.white24, padding:EdgeInsets.symmetric(horizontal:24, vertical:14)), child:Text("غفوة 5 دقائق")),
      FilmedButton(label:"ايقاف", onPressed:widget.onStop),
    ])
  ])));
}

class FilmedButton extends StatelessWidget{ final String label; final VoidCallback onPressed; const FilmedButton({required this.label, required this.onPressed}); @override Widget build(BuildContext c)=> FilledButton(onPressed:onPressed, style: FilmedButton.styleFrom(backgroundColor:Colors.white, padding:EdgeInsets.symmetric(horizontal:28, vertical:14), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))), child:Text(label, style:TextStyle(color:Colors.black, fontWeight:FontWeight.bold))); }