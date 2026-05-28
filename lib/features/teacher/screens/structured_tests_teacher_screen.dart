import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart'; // kApiBase, authHeaders()

// ─── Theme ────────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _border  = Color(0xFF21262D);
const _border2 = Color(0xFF30363D);
const _text    = Color(0xFFE6EDF3);
const _muted   = Color(0xFF8B949E);
const _subtle  = Color(0xFF6E7681);
const _green   = Color(0xFF2EA043);
const _greenL  = Color(0xFF3FB950);
const _greenBg = Color(0xFF1A3A2A);
const _blue    = Color(0xFF58A6FF);
const _blueBg  = Color(0xFF0D2A3D);
const _yellow  = Color(0xFFE3B341);
const _yellowBg= Color(0xFF3D2E0A);
const _red     = Color(0xFFF85149);
const _redBg   = Color(0xFF3D1A1A);

const Map<String, List<String>> _subjectTopics = {
  'Biology':         ['Cell Structure','Cell Division','Photosynthesis','Respiration','Transport in Plants','Circulatory System','Nutrition','Excretion','Nervous System','Genetics','Ecology','Disease and Immunity'],
  'Mathematics':     ['Algebra','Linear Equations','Quadratic Equations','Functions and Graphs','Trigonometry','Vectors','Matrices','Statistics','Probability','Mensuration'],
  'Chemistry':       ['Atomic Structure','Periodic Table','Chemical Bonding','Acids and Bases','Redox Reactions','Electrochemistry','Rates of Reaction','Organic Chemistry'],
  'Physics':         ['Motion','Newton\'s Laws','Work, Energy, Power','Waves','Light','Electricity','Magnetism','Radioactivity'],
  'English':         ['Comprehension','Essay Writing','Grammar','Literature','Report Writing','Letter Writing'],
  'Geography':       ['Map Reading','Climate','Physical Features of Malawi','Agriculture','Population','Environmental Conservation'],
  'History':         ['Pre-colonial Malawi','Colonial Rule','Independence','Post-Independence'],
  'Civic Education': ['Human Rights','Constitution','Government','Democracy','Gender Equality'],
  'Computer Studies':['Hardware','Software','Networking','Programming','Web Design','Data Representation'],
};

// ─── Models ───────────────────────────────────────────────────────────────────

class _TQuestion {
  String id, text, type, markingGuidance;
  int marks;
  _TQuestion({required this.id, this.text='', this.type='short',
    this.marks=2, this.markingGuidance=''});
  Map<String,dynamic> toJson() => {
    'id':id,'text':text,'type':type,'marks':marks,
    'markingGuidance':markingGuidance,
  };
  factory _TQuestion.fromJson(Map<String,dynamic> j) => _TQuestion(
    id:               j['id']?.toString()              ?? '',
    text:             j['text']?.toString()            ?? '',
    type:             j['type']?.toString()            ?? 'short',
    marks:            (j['marks'] as num?)?.toInt()    ?? 2,
    markingGuidance:  j['markingGuidance']?.toString() ?? '',
  );
  _TQuestion copy() => _TQuestion(id:id,text:text,type:type,
    marks:marks,markingGuidance:markingGuidance);
}

class _Test {
  final String  id, title, status;
  final String? subject, form, duration;
  final int     totalMarks;
  final List<_TQuestion> questions;
  final DateTime? createdAt;
  const _Test({required this.id,required this.title,required this.status,
    this.subject,this.form,this.duration,required this.totalMarks,
    required this.questions,this.createdAt});
  factory _Test.fromJson(Map<String,dynamic> j) {
    DateTime? ca;
    try { if (j['createdAt'] is String) ca=DateTime.parse(j['createdAt']); } catch(_) {}
    return _Test(
      id:         j['id']?.toString()        ?? '',
      title:      j['title']?.toString()     ?? '',
      status:     j['status']?.toString()    ?? 'DRAFT',
      subject:    j['subject']?.toString(),
      form:       j['form']?.toString(),
      duration:   j['duration']?.toString(),
      totalMarks: (j['totalMarks'] as num?)?.toInt() ?? 0,
      questions:  (j['questions'] as List? ?? [])
          .map((q)=>_TQuestion.fromJson(q as Map<String,dynamic>)).toList(),
      createdAt:  ca,
    );
  }
  String get formattedDate {
    if (createdAt==null) return '—';
    const m=['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${createdAt!.day} ${m[createdAt!.month]} ${createdAt!.year}';
  }
}

class _Submission {
  final String  id, status;
  final String? studentName;
  final int?    totalScore, percentage;
  final List<Map<String,dynamic>> answers, aiMarking, finalMarks;
  final DateTime? submittedAt;
  const _Submission({required this.id,required this.status,this.studentName,
    this.totalScore,this.percentage,required this.answers,
    required this.aiMarking,required this.finalMarks,this.submittedAt});
  factory _Submission.fromJson(Map<String,dynamic> j) {
    DateTime? sa;
    try { if (j['submittedAt'] is String) sa=DateTime.parse(j['submittedAt']); } catch(_) {}
    final student = j['student'] as Map<String,dynamic>?;
    final name = student!=null
        ? '${student['firstName']??''} ${student['lastName']??''}'.trim()
        : 'Student #${j['studentId']}';
    return _Submission(
      id:          j['id']?.toString()     ?? '',
      status:      j['status']?.toString() ?? 'SUBMITTED',
      studentName: name,
      totalScore:  (j['totalScore']  as num?)?.toInt(),
      percentage:  (j['percentage']  as num?)?.toInt(),
      answers:     List<Map<String,dynamic>>.from(j['answers']    ?? []),
      aiMarking:   List<Map<String,dynamic>>.from(j['aiMarking']  ?? []),
      finalMarks:  List<Map<String,dynamic>>.from(j['finalMarks'] ?? []),
      submittedAt: sa,
    );
  }
  String get formattedDate {
    if (submittedAt==null) return '—';
    return '${submittedAt!.day}/${submittedAt!.month}/${submittedAt!.year}';
  }
}

// ─── Toast ────────────────────────────────────────────────────────────────────

void _toast(BuildContext ctx, String msg, {bool error=false}) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Row(children:[
      Text(error?'⚠️ ':'✅ '),
      Expanded(child:Text(msg,style:TextStyle(
        color:error?_red:_greenL,fontWeight:FontWeight.w600,fontSize:13))),
    ]),
    backgroundColor: error?_redBg:_greenBg,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius:BorderRadius.circular(8),
      side:BorderSide(color:error?_red:_green),
    ),
  ));
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child; final Color? borderColor;
  const _Card({required this.child,this.borderColor});
  @override Widget build(BuildContext ctx) => Container(
    width:double.infinity,
    padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(
      color:_surface,
      border:Border.all(color:borderColor??_border),
      borderRadius:BorderRadius.circular(10),
    ),
    child:child,
  );
}

class _Badge extends StatelessWidget {
  final String label; final Color fg,bg;
  const _Badge(this.label,{this.fg=_green,this.bg=_greenBg});
  @override Widget build(BuildContext ctx) => Container(
    padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
    decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(20),
      border:Border.all(color:fg.withValues(alpha:0.4))),
    child:Text(label,style:TextStyle(color:fg,fontSize:11,fontWeight:FontWeight.w600)),
  );
}

InputDecoration _inputDec(String hint,{int maxLines=1}) => InputDecoration(
  hintText:hint,hintStyle:const TextStyle(color:_subtle),
  filled:true,fillColor:_bg,
  contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:10),
  border:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_border)),
  enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_border)),
  focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(8),borderSide:const BorderSide(color:_green,width:1.5)),
);

// ─── Main Screen ──────────────────────────────────────────────────────────────

class StructuredTestsTeacherScreen extends StatefulWidget {
  const StructuredTestsTeacherScreen({super.key});
  @override State<StructuredTestsTeacherScreen> createState() => _STTState();
}

class _STTState extends State<StructuredTestsTeacherScreen> {
  List<_Test> _tests   = [];
  bool        _loading = true;
  // navigation stack
  Widget? _child;

  @override void initState() { super.initState(); _fetchTests(); }

  Future<void> _fetchTests() async {
    setState(() => _loading=true);
    try {
      final h = await authHeaders();
      final r = await http.get(Uri.parse('$kApiBase/structured-tests/mine'),headers:h);
      if (r.statusCode<300&&mounted) {
        setState(()=>_tests=(jsonDecode(r.body) as List)
            .map((e)=>_Test.fromJson(e as Map<String,dynamic>)).toList());
      }
    } catch(_) {}
    finally { if(mounted) setState(()=>_loading=false); }
  }

  void _push(Widget w) => setState(()=>_child=w);
  void _pop({bool refresh=false}) {
    setState(()=>_child=null);
    if(refresh) _fetchTests();
  }

  @override
  Widget build(BuildContext ctx) {
    if (_child!=null) return _child!;
    return Scaffold(
      backgroundColor:_bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor:_green,
        onPressed:()=>_push(_CreateTestScreen(onDone:_pop)),
        icon:const Icon(Icons.add,color:Colors.white),
        label:const Text('New Test',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color:_green,
        onRefresh:_fetchTests,
        child: _loading
          ? const Center(child:CircularProgressIndicator(color:_green))
          : ListView.builder(
              padding:const EdgeInsets.fromLTRB(14,14,14,100),
              itemCount:_tests.length+1,
              itemBuilder:(_,i){
                if(i==0) return _header();
                return _testCard(_tests[i-1]);
              },
            ),
      ),
    );
  }

  Widget _header() => Padding(
    padding:const EdgeInsets.only(bottom:16),
    child:_Card(
      borderColor:_green,
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Row(children:[
          Text('📝',style:TextStyle(fontSize:22)),
          SizedBox(width:8),
          Text('Structured Tests',style:TextStyle(color:_text,fontSize:18,fontWeight:FontWeight.w800)),
        ]),
        const SizedBox(height:4),
        Text('${_tests.length} test${_tests.length!=1?"s":""} created',
            style:const TextStyle(color:_muted,fontSize:12)),
        const SizedBox(height:12),
        Row(children:[
          _miniStat('${_tests.length}','Total'),
          const SizedBox(width:8),
          _miniStat('${_tests.where((t)=>t.status=="PUBLISHED").length}','Published'),
          const SizedBox(width:8),
          _miniStat('${_tests.where((t)=>t.status=="DRAFT").length}','Drafts'),
        ]),
      ]),
    ),
  );

  Widget _miniStat(String val,String lbl) => Expanded(child:Container(
    padding:const EdgeInsets.symmetric(vertical:10),
    decoration:BoxDecoration(color:_bg,borderRadius:BorderRadius.circular(8),
      border:Border.all(color:_border)),
    child:Column(children:[
      Text(val,style:const TextStyle(color:_green,fontSize:18,fontWeight:FontWeight.w800)),
      Text(lbl,style:const TextStyle(color:_subtle,fontSize:10)),
    ]),
  ));

  Widget _testCard(_Test t) {
    final statusColor = t.status=='PUBLISHED'?_green:t.status=='CLOSED'?_red:_muted;
    final statusBg    = t.status=='PUBLISHED'?_greenBg:t.status=='CLOSED'?_redBg:_border;
    return Container(
      margin:const EdgeInsets.only(bottom:12),
      child:_Card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Expanded(child:Text(t.title,style:const TextStyle(color:_text,
              fontWeight:FontWeight.w700,fontSize:15),overflow:TextOverflow.ellipsis)),
          _Badge(t.status,fg:statusColor,bg:statusBg),
        ]),
        const SizedBox(height:8),
        Wrap(spacing:14,children:[
          if(t.subject!=null) _meta('📚',t.subject!),
          if(t.form!=null)    _meta('🎓',t.form!),
          if(t.duration!=null)_meta('⏱',t.duration!),
          _meta('❓','${t.questions.length} questions'),
          _meta('📊','${t.totalMarks} marks'),
          _meta('📅',t.formattedDate),
        ]),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:OutlinedButton.icon(
            onPressed:()=>_push(_SubmissionsScreen(test:t,onBack:_pop)),
            icon:const Icon(Icons.list_alt,size:16),
            label:const Text('Submissions',style:TextStyle(fontSize:12)),
            style:OutlinedButton.styleFrom(foregroundColor:_blue,
              side:const BorderSide(color:_blue),
              padding:const EdgeInsets.symmetric(vertical:8),
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
          )),
          const SizedBox(width:8),
          Expanded(child:ElevatedButton.icon(
            onPressed:()=>_push(_CreateTestScreen(editingTest:t,onDone:_pop)),
            icon:const Icon(Icons.edit,size:16),
            label:const Text('Edit',style:TextStyle(fontSize:12)),
            style:ElevatedButton.styleFrom(backgroundColor:_surface,
              foregroundColor:_text,
              side:const BorderSide(color:_border2),
              padding:const EdgeInsets.symmetric(vertical:8),
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
          )),
        ]),
      ])),
    );
  }

  Widget _meta(String icon,String val) => Row(mainAxisSize:MainAxisSize.min,children:[
    Text(icon,style:const TextStyle(fontSize:11)),
    const SizedBox(width:3),
    Text(val,style:const TextStyle(color:_muted,fontSize:11)),
  ]);
}

// ─── Create / Edit Test Screen ────────────────────────────────────────────────

class _CreateTestScreen extends StatefulWidget {
  final _Test?                    editingTest;
  final void Function({bool refresh}) onDone;
  const _CreateTestScreen({this.editingTest,required this.onDone});
  @override State<_CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<_CreateTestScreen> {
  int  _step = 1; // 1=AI gen, 2=edit
  bool _generating=false, _saving=false;

  // AI gen form
  String _genSubject='Biology',_genForm='Form 1',_genTopic='',_genCount='5';

  // Meta
  late String _title,_subject,_form,_duration,_instructions;
  late List<_TQuestion> _questions;
  late String _status;

  @override
  void initState() {
    super.initState();
    final t = widget.editingTest;
    _title        = t?.title        ?? '';
    _subject      = t?.subject      ?? 'Biology';
    _form         = t?.form         ?? 'Form 1';
    _duration     = t?.duration     ?? '60 minutes';
    _instructions = 'Answer all questions. Show your working where appropriate.';
    _questions    = t?.questions.map((q)=>q.copy()).toList() ?? [];
    _status       = t?.status       ?? 'DRAFT';
    if (t!=null) _step=2;
  }

  List<String> get _topics => _subjectTopics[_genSubject] ?? [];

  Future<void> _generate() async {
    if (_genTopic.isEmpty) { _toast(context,'Please select a topic.',error:true); return; }
    setState(()=>_generating=true);
    try {
      final h = await authHeaders();
      final r = await http.post(
        Uri.parse('$kApiBase/structured-tests/generate-questions'),
        headers:h,
        body:jsonEncode({'subject':_genSubject,'form':_genForm,
          'topic':_genTopic,'count':int.tryParse(_genCount)??5}),
      );
      if (r.statusCode<300) {
        final d = jsonDecode(r.body);
        setState((){
          _questions = (d['questions'] as List)
              .map((q)=>_TQuestion.fromJson(q as Map<String,dynamic>)).toList();
          _subject  = _genSubject;
          _form     = _genForm;
          if (_title.isEmpty) _title='$_genSubject — $_genTopic ($_genForm)';
          _step=2;
        });
      } else {
        _toast(context,'Generation failed.',error:true);
      }
    } catch(e) { _toast(context,'Error: $e',error:true); }
    finally { if(mounted) setState(()=>_generating=false); }
  }

  Future<void> _save(String publishStatus) async {
    if (_title.trim().isEmpty||_questions.isEmpty) {
      _toast(context,'Title and at least one question required.',error:true); return;
    }
    setState(()=>_saving=true);
    try {
      final h = await authHeaders();
      final url    = widget.editingTest!=null
          ? '$kApiBase/structured-tests/${widget.editingTest!.id}'
          : '$kApiBase/structured-tests';
      final method = widget.editingTest!=null ? 'PATCH' : 'POST';
      final body   = jsonEncode({
        'title':_title,'subject':_subject,'form':_form,
        'duration':_duration,'instructions':_instructions,
        'questions':_questions.map((q)=>q.toJson()).toList(),
        'status':publishStatus,
      });
      final r = method=='POST'
          ? await http.post(Uri.parse(url),headers:h,body:body)
          : await http.patch(Uri.parse(url),headers:h,body:body);
      if (r.statusCode<300) {
        _toast(context,publishStatus=='PUBLISHED'?'Test published!':'Draft saved.');
        widget.onDone(refresh:true);
      } else {
        final d=jsonDecode(r.body);
        _toast(context,d['message']?.toString()??'Failed.',error:true);
      }
    } catch(e) { _toast(context,'Error: $e',error:true); }
    finally { if(mounted) setState(()=>_saving=false); }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor:_bg,
    appBar:AppBar(
      backgroundColor:_surface,foregroundColor:_text,elevation:0,
      leading:IconButton(
        icon:const Icon(Icons.arrow_back),
        onPressed:()=>widget.onDone(refresh:false),
      ),
      title:Text(widget.editingTest!=null?'Edit Test':'Create Test',
          style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700)),
      actions:[
        if(_step==2) TextButton(
          onPressed:()=>setState(()=>_step=1),
          child:const Text('🤖 Re-gen',style:TextStyle(color:_blue,fontSize:13)),
        ),
      ],
    ),
    body:SingleChildScrollView(
      padding:const EdgeInsets.all(14),
      child:Column(children:[
        if(_step==1) _buildGenStep(),
        if(_step==2) _buildEditStep(),
        const SizedBox(height:40),
      ]),
    ),
  );

  // ── Step 1: AI generation ──────────────────────────────────────────────────
  Widget _buildGenStep() => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _Card(borderColor:_green,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('🤖 Generate with AI',style:TextStyle(color:_green,
          fontSize:15,fontWeight:FontWeight.w700)),
      const SizedBox(height:14),
      _lbl('Subject'),
      _ddField(value:_genSubject,items:_subjectTopics.keys.toList(),
        onChanged:(v){setState((){_genSubject=v!;_genTopic='';});}),
      const SizedBox(height:10),
      _lbl('Form'),
      _ddField(value:_genForm,items:['Form 1','Form 2','Form 3','Form 4'],
        onChanged:(v)=>setState(()=>_genForm=v!)),
      const SizedBox(height:10),
      _lbl('Topic'),
      _ddField(
        value:_topics.contains(_genTopic)?_genTopic:null,
        hint:'Select topic',
        items:_topics,
        onChanged:(v)=>setState(()=>_genTopic=v??''),
      ),
      const SizedBox(height:10),
      _lbl('Number of questions'),
      TextField(
        controller:TextEditingController(text:_genCount),
        keyboardType:TextInputType.number,
        style:const TextStyle(color:_text,fontSize:13),
        decoration:_inputDec('5'),
        onChanged:(v)=>_genCount=v,
      ),
      const SizedBox(height:16),
      Row(children:[
        Expanded(child:ElevatedButton.icon(
          onPressed:_generating?null:_generate,
          icon:_generating
              ? const SizedBox(width:16,height:16,
                  child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
              : const Icon(Icons.smart_toy),
          label:Text(_generating?'Generating…':'Generate Questions'),
          style:ElevatedButton.styleFrom(backgroundColor:_green,foregroundColor:Colors.white,
            minimumSize:const Size.fromHeight(46),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
        )),
        const SizedBox(width:10),
        OutlinedButton(
          onPressed:(){
            _questions=[_TQuestion(id:'q${DateTime.now().millisecondsSinceEpoch}')];
            setState(()=>_step=2);
          },
          style:OutlinedButton.styleFrom(foregroundColor:_muted,
            side:const BorderSide(color:_border2),
            minimumSize:const Size(0,46),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
          child:const Text('Manual'),
        ),
      ]),
    ])),
  ]);

  // ── Step 2: Edit + save ────────────────────────────────────────────────────
  Widget _buildEditStep() => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    // Meta card
    _Card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Test Details',style:TextStyle(color:_green,fontSize:14,fontWeight:FontWeight.w700)),
      const SizedBox(height:12),
      _lbl('Title *'),
      TextField(
        controller:TextEditingController(text:_title),
        style:const TextStyle(color:_text,fontSize:13),
        decoration:_inputDec('e.g. Biology End of Term Test'),
        onChanged:(v)=>_title=v,
      ),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          _lbl('Subject'),
          TextField(
            controller:TextEditingController(text:_subject),
            style:const TextStyle(color:_text,fontSize:13),
            decoration:_inputDec('Subject'),onChanged:(v)=>_subject=v,
          ),
        ])),
        const SizedBox(width:10),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          _lbl('Form'),
          TextField(
            controller:TextEditingController(text:_form),
            style:const TextStyle(color:_text,fontSize:13),
            decoration:_inputDec('Form'),onChanged:(v)=>_form=v,
          ),
        ])),
      ]),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          _lbl('Duration'),
          TextField(
            controller:TextEditingController(text:_duration),
            style:const TextStyle(color:_text,fontSize:13),
            decoration:_inputDec('60 minutes'),onChanged:(v)=>_duration=v,
          ),
        ])),
        const SizedBox(width:10),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          _lbl('Total marks'),
          Container(
            padding:const EdgeInsets.symmetric(horizontal:12,vertical:12),
            decoration:BoxDecoration(color:_bg,borderRadius:BorderRadius.circular(8),
              border:Border.all(color:_border)),
            child:Text('${_questions.fold(0,(s,q)=>s+q.marks)}',
                style:const TextStyle(color:_green,fontSize:18,fontWeight:FontWeight.w800)),
          ),
        ])),
      ]),
    ])),
    const SizedBox(height:14),

    // Questions
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text('Questions (${_questions.length})',
          style:const TextStyle(color:_text,fontSize:14,fontWeight:FontWeight.w700)),
      TextButton.icon(
        onPressed:()=>setState(()=>_questions.add(
          _TQuestion(id:'q${DateTime.now().millisecondsSinceEpoch}'))),
        icon:const Icon(Icons.add,color:_green,size:16),
        label:const Text('Add',style:TextStyle(color:_green,fontSize:13)),
      ),
    ]),
    const SizedBox(height:8),
    ..._questions.asMap().entries.map((e)=>_QuestionCard(
      q:e.value, index:e.key,
      canRemove:_questions.length>1,
      onChange:(q){setState(()=>_questions[e.key]=q);},
      onRemove:(){setState(()=>_questions.removeAt(e.key));},
    )),
    const SizedBox(height:16),

    // Save buttons
    _Card(child:Column(children:[
      Row(children:[
        Expanded(child:OutlinedButton(
          onPressed:_saving?null:()=>_save('DRAFT'),
          style:OutlinedButton.styleFrom(foregroundColor:_muted,
            side:const BorderSide(color:_border2),
            minimumSize:const Size.fromHeight(46),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
          child:const Text('💾 Save Draft'),
        )),
        const SizedBox(width:10),
        Expanded(flex:2,child:ElevatedButton(
          onPressed:_saving?null:()=>_save('PUBLISHED'),
          style:ElevatedButton.styleFrom(backgroundColor:_green,foregroundColor:Colors.white,
            minimumSize:const Size.fromHeight(46),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
          child:Text(_saving?'Saving…':
            widget.editingTest?.status=='PUBLISHED'?'✅ Save & Keep Published':'🚀 Publish'),
        )),
      ]),
      if (widget.editingTest?.status=='PUBLISHED') ...[
        const SizedBox(height:8),
        SizedBox(width:double.infinity,child:OutlinedButton(
          onPressed:_saving?null:()=>_save('CLOSED'),
          style:OutlinedButton.styleFrom(foregroundColor:_red,
            side:const BorderSide(color:_red),
            minimumSize:const Size.fromHeight(42),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
          child:const Text('🔒 Close Test'),
        )),
      ],
    ])),
  ]);

  Widget _lbl(String t) => Padding(
    padding:const EdgeInsets.only(bottom:5),
    child:Text(t,style:const TextStyle(color:_subtle,fontSize:11)),
  );

  Widget _ddField({required String? value,String? hint,required List<String> items,
      required ValueChanged<String?> onChanged}) =>
    DropdownButtonFormField<String>(
      value:items.contains(value)?value:null,
      dropdownColor:_surface,
      style:const TextStyle(color:_text,fontSize:13),
      decoration:_inputDec(hint??''),
      hint:hint!=null?Text(hint,style:const TextStyle(color:_subtle,fontSize:13)):null,
      items:items.map((i)=>DropdownMenuItem(value:i,child:Text(i))).toList(),
      onChanged:onChanged,
    );
}

// ─── Question editor card ─────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final _TQuestion q;
  final int index;
  final bool canRemove;
  final ValueChanged<_TQuestion> onChange;
  final VoidCallback onRemove;
  const _QuestionCard({required this.q,required this.index,required this.canRemove,
    required this.onChange,required this.onRemove});

  @override
  Widget build(BuildContext ctx) => Container(
    margin:const EdgeInsets.only(bottom:12),
    decoration:BoxDecoration(color:_bg,borderRadius:BorderRadius.circular(10),
      border:Border.all(color:_border)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      // Header
      Container(
        padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
        decoration:const BoxDecoration(color:_surface,
          borderRadius:BorderRadius.vertical(top:Radius.circular(10)),
          border:Border(bottom:BorderSide(color:_border))),
        child:Row(children:[
          Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
            decoration:BoxDecoration(color:_greenBg,borderRadius:BorderRadius.circular(4)),
            child:Text('Q${index+1}',style:const TextStyle(color:_green,
                fontWeight:FontWeight.w700,fontSize:12))),
          const Spacer(),
          if(canRemove) GestureDetector(onTap:onRemove,
            child:const Text('✕ Remove',style:TextStyle(color:_red,fontSize:12))),
        ]),
      ),
      Padding(padding:const EdgeInsets.all(12),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          // Question text
          TextField(
            controller:TextEditingController(text:q.text),
            maxLines:2,style:const TextStyle(color:_text,fontSize:13),
            decoration:_inputDec('Question text…'),
            onChanged:(v){final n=q.copy();n.text=v;onChange(n);},
          ),
          const SizedBox(height:10),
          Row(children:[
            // Type
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Type',style:TextStyle(color:_subtle,fontSize:11)),
              const SizedBox(height:4),
              DropdownButtonFormField<String>(
                value:q.type,dropdownColor:_surface,
                style:const TextStyle(color:_text,fontSize:12),
                decoration:_inputDec(''),
                items:['short','structured','long'].map((t)=>
                  DropdownMenuItem(value:t,child:Text(t))).toList(),
                onChanged:(v){final n=q.copy();n.type=v??q.type;onChange(n);},
              ),
            ])),
            const SizedBox(width:10),
            // Marks
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Marks',style:TextStyle(color:_subtle,fontSize:11)),
              const SizedBox(height:4),
              TextField(
                controller:TextEditingController(text:'${q.marks}'),
                keyboardType:TextInputType.number,
                style:const TextStyle(color:_text,fontSize:13),
                decoration:_inputDec('2'),
                onChanged:(v){final n=q.copy();n.marks=int.tryParse(v)??q.marks;onChange(n);},
              ),
            ])),
          ]),
          const SizedBox(height:10),
          const Text('Marking guidance (private)',style:TextStyle(color:_subtle,fontSize:11)),
          const SizedBox(height:4),
          TextField(
            controller:TextEditingController(text:q.markingGuidance),
            maxLines:2,style:const TextStyle(color:_muted,fontSize:12),
            decoration:_inputDec('Key points the answer must include…'),
            onChanged:(v){final n=q.copy();n.markingGuidance=v;onChange(n);},
          ),
        ],
      )),
    ]),
  );
}

// ─── Submissions list ─────────────────────────────────────────────────────────

class _SubmissionsScreen extends StatefulWidget {
  final _Test test;
  final void Function({bool refresh}) onBack;
  const _SubmissionsScreen({required this.test,required this.onBack});
  @override State<_SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<_SubmissionsScreen> {
  List<_Submission> _subs    = [];
  bool              _loading = true;
  _Submission?      _marking;

  @override void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(()=>_loading=true);
    try {
      final h = await authHeaders();
      final r = await http.get(
        Uri.parse('$kApiBase/structured-tests/${widget.test.id}/submissions'),headers:h);
      if(r.statusCode<300&&mounted)
        setState(()=>_subs=(jsonDecode(r.body) as List)
          .map((e)=>_Submission.fromJson(e as Map<String,dynamic>)).toList());
    } catch(_) {}
    finally { if(mounted) setState(()=>_loading=false); }
  }

  @override
  Widget build(BuildContext ctx) {
    if(_marking!=null) return _MarkScreen(
      submission:_marking!, test:widget.test,
      onBack:({bool refresh=false}){
        setState(()=>_marking=null);
        if(refresh) _fetch();
      },
    );

    final marked  = _subs.where((s)=>s.status=='MARKED').length;
    final pending = _subs.length-marked;

    return Scaffold(
      backgroundColor:_bg,
      appBar:AppBar(
        backgroundColor:_surface,foregroundColor:_text,elevation:0,
        leading:IconButton(icon:const Icon(Icons.arrow_back),
          onPressed:()=>widget.onBack(refresh:false)),
        title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(widget.test.title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700),
            overflow:TextOverflow.ellipsis),
          Text('$marked marked · $pending pending',
              style:const TextStyle(color:_muted,fontSize:11)),
        ]),
      ),
      body:RefreshIndicator(
        color:_green,onRefresh:_fetch,
        child:_loading
          ? const Center(child:CircularProgressIndicator(color:_green))
          : _subs.isEmpty
              ? const Center(child:Padding(padding:EdgeInsets.all(40),
                  child:Column(mainAxisSize:MainAxisSize.min,children:[
                    Text('📭',style:TextStyle(fontSize:48)),
                    SizedBox(height:12),
                    Text('No submissions yet.',style:TextStyle(color:_muted)),
                  ])))
              : ListView.builder(
                  padding:const EdgeInsets.all(14),
                  itemCount:_subs.length,
                  itemBuilder:(_,i)=>_subCard(_subs[i]),
                ),
      ),
    );
  }

  Widget _subCard(_Submission s) => Container(
    margin:const EdgeInsets.only(bottom:10),
    child:_Card(child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(s.studentName??'Student',style:const TextStyle(color:_text,
            fontWeight:FontWeight.w600,fontSize:14)),
        const SizedBox(height:4),
        Wrap(spacing:8,children:[
          if(s.status=='MARKED') ...[
            _Badge('Marked',fg:_greenL,bg:_greenBg),
            _Badge('${s.totalScore}/${widget.test.totalMarks} — ${s.percentage}%',
              fg:_blue,bg:_blueBg),
          ] else _Badge('Awaiting',fg:_yellow,bg:_yellowBg),
          Text(s.formattedDate,style:const TextStyle(color:_subtle,fontSize:11)),
        ]),
      ])),
      const SizedBox(width:10),
      ElevatedButton(
        onPressed:()=>setState(()=>_marking=s),
        style:ElevatedButton.styleFrom(backgroundColor:_green,foregroundColor:Colors.white,
          padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
        child:Text(s.status=='MARKED'?'Review':'Mark',
            style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600)),
      ),
    ])),
  );
}

// ─── Mark submission screen ───────────────────────────────────────────────────

class _MarkScreen extends StatefulWidget {
  final _Submission submission;
  final _Test       test;
  final void Function({bool refresh}) onBack;
  const _MarkScreen({required this.submission,required this.test,required this.onBack});
  @override State<_MarkScreen> createState() => _MarkScreenState();
}

class _MarkScreenState extends State<_MarkScreen> {
  late List<Map<String,dynamic>> _marks;
  late String _comment;
  bool _aiLoading=false, _saving=false;

  @override
  void initState() {
    super.initState();
    _comment = widget.submission.finalMarks.isNotEmpty
        ? '' : '';
    _marks = widget.test.questions.map((q){
      final ex = widget.submission.finalMarks
          .firstWhere((m)=>m['questionId']==q.id,orElse:()=>{});
      final ai = widget.submission.aiMarking
          .firstWhere((m)=>m['questionId']==q.id,orElse:()=>{});
      return {
        'questionId': q.id,
        'mark':       ex['mark']     ?? ai['suggestedMark'] ?? 0,
        'feedback':   ex['feedback'] ?? ai['feedback']      ?? '',
      };
    }).toList();
  }

  Future<void> _runAI() async {
    setState(()=>_aiLoading=true);
    try {
      final h = await authHeaders();
      final r = await http.post(
        Uri.parse('$kApiBase/structured-tests/submissions/${widget.submission.id}/ai-mark'),
        headers:h,
      );
      if(r.statusCode<300) {
        final d=jsonDecode(r.body);
        final ai=List<Map<String,dynamic>>.from(d['aiMarking']??[]);
        setState(()=>_marks=_marks.map((m){
          final a=ai.firstWhere((a)=>a['questionId']==m['questionId'],orElse:()=>{});
          if(a.isEmpty) return m;
          return {...m,'mark':a['suggestedMark'],'feedback':a['feedback']};
        }).toList());
        _toast(context,'AI suggestions loaded — review before saving.');
      } else { _toast(context,'AI marking failed.',error:true); }
    } catch(e) { _toast(context,'Error: $e',error:true); }
    finally { if(mounted) setState(()=>_aiLoading=false); }
  }

  Future<void> _save() async {
    setState(()=>_saving=true);
    try {
      final h = await authHeaders();
      final r = await http.patch(
        Uri.parse('$kApiBase/structured-tests/submissions/${widget.submission.id}/final-marks'),
        headers:h,
        body:jsonEncode({'finalMarks':_marks,'teacherComment':_comment}),
      );
      if(r.statusCode<300) {
        _toast(context,'Marks saved!');
        widget.onBack(refresh:true);
      } else { _toast(context,'Failed to save.',error:true); }
    } catch(e) { _toast(context,'Error: $e',error:true); }
    finally { if(mounted) setState(()=>_saving=false); }
  }

  int get _totalAwarded => _marks.fold(0,(s,m)=>(s+(m['mark'] as num)).toInt());

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor:_bg,
    appBar:AppBar(
      backgroundColor:_surface,foregroundColor:_text,elevation:0,
      leading:IconButton(icon:const Icon(Icons.arrow_back),
        onPressed:()=>widget.onBack(refresh:false)),
      title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Marking: ${widget.submission.studentName??'Student'}',
            style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700)),
        Text(widget.test.title,style:const TextStyle(color:_muted,fontSize:11),
          overflow:TextOverflow.ellipsis),
      ]),
      actions:[
        Padding(padding:const EdgeInsets.only(right:8),
          child:Center(child:Text(
            '$_totalAwarded/${widget.test.totalMarks}',
            style:const TextStyle(color:_green,fontWeight:FontWeight.w800,fontSize:16),
          ))),
      ],
    ),
    body:ListView(padding:const EdgeInsets.all(14),children:[
      // AI button
      ElevatedButton.icon(
        onPressed:_aiLoading?null:_runAI,
        icon:_aiLoading
            ? const SizedBox(width:16,height:16,
                child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
            : const Icon(Icons.smart_toy),
        label:Text(_aiLoading?'AI is marking…':'🤖 Get AI Suggestions'),
        style:ElevatedButton.styleFrom(
          backgroundColor:_blueBg,foregroundColor:_blue,
          side:const BorderSide(color:_blue),
          minimumSize:const Size.fromHeight(44),
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
      ),
      const SizedBox(height:14),

      // Per-question marking
      ...widget.test.questions.asMap().entries.map((e){
        final q   = e.value;
        final i   = e.key;
        final m   = _marks[i];
        final ans = widget.submission.answers
            .firstWhere((a)=>a['questionId']==q.id,orElse:()=>{})['answer']
            ?.toString() ?? '(no answer)';
        final ai  = widget.submission.aiMarking
            .firstWhere((a)=>a['questionId']==q.id,orElse:()=>{}); 

        return Container(
          margin:const EdgeInsets.only(bottom:14),
          child:_Card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              Expanded(child:Text('Q${i+1}. ${q.text}',
                style:const TextStyle(color:_text,fontWeight:FontWeight.w600,fontSize:13))),
              _Badge('${q.marks} marks'),
            ]),
            const SizedBox(height:10),
            // Student answer
            Container(padding:const EdgeInsets.all(10),
              decoration:BoxDecoration(color:_bg,borderRadius:BorderRadius.circular(8),
                border:Border.all(color:_border)),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('Student answer',style:TextStyle(color:_subtle,
                    fontSize:10,fontWeight:FontWeight.w600)),
                const SizedBox(height:4),
                Text(ans,style:const TextStyle(color:_text,fontSize:13)),
              ])),
            // Marking guidance
            if(q.markingGuidance.isNotEmpty) ...[
              const SizedBox(height:8),
              Container(padding:const EdgeInsets.all(10),
                decoration:BoxDecoration(color:_greenBg,borderRadius:BorderRadius.circular(8),
                  border:Border.all(color:_green.withValues(alpha:0.3))),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  const Text('Marking guidance',style:TextStyle(color:_subtle,
                      fontSize:10,fontWeight:FontWeight.w600)),
                  const SizedBox(height:4),
                  Text(q.markingGuidance,style:const TextStyle(color:_greenL,fontSize:12)),
                ])),
            ],
            // AI suggestion
            if(ai.isNotEmpty) ...[
              const SizedBox(height:8),
              Container(padding:const EdgeInsets.all(10),
                decoration:BoxDecoration(color:_blueBg,borderRadius:BorderRadius.circular(8),
                  border:Border.all(color:_blue.withValues(alpha:0.3))),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                    const Text('🤖 AI suggests',style:TextStyle(color:_blue,
                        fontSize:10,fontWeight:FontWeight.w700)),
                    _Badge('${ai['suggestedMark']}/${ai['maxMark']}',fg:_blue,bg:_blueBg),
                  ]),
                  const SizedBox(height:4),
                  Text(ai['feedback']?.toString()??'',
                      style:const TextStyle(color:_muted,fontSize:12)),
                ])),
            ],
            const SizedBox(height:10),
            // Mark + feedback inputs
            Row(children:[
              SizedBox(width:90,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('Mark',style:TextStyle(color:_subtle,fontSize:11)),
                const SizedBox(height:4),
                TextFormField(
                  initialValue:'${m['mark']}',
                  keyboardType:TextInputType.number,
                  style:const TextStyle(color:_text,fontSize:13),
                  decoration:_inputDec('0'),
                  onChanged:(v){
                    final n=Map<String,dynamic>.from(m);
                    n['mark']=int.tryParse(v)??0;
                    setState(()=>_marks[i]=n);
                  },
                ),
              ])),
              const SizedBox(width:10),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('Feedback',style:TextStyle(color:_subtle,fontSize:11)),
                const SizedBox(height:4),
                TextFormField(
                  initialValue:m['feedback']?.toString()??'',
                  style:const TextStyle(color:_text,fontSize:13),
                  decoration:_inputDec('Write feedback…'),
                  onChanged:(v){
                    final n=Map<String,dynamic>.from(m);
                    n['feedback']=v;
                    setState(()=>_marks[i]=n);
                  },
                ),
              ])),
            ]),
          ])),
        );
      }),

      // Overall comment
      _Card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Overall comment',style:TextStyle(color:_subtle,fontSize:11)),
        const SizedBox(height:6),
        TextField(
          maxLines:3,style:const TextStyle(color:_text,fontSize:13),
          decoration:_inputDec('Overall comments on student performance…'),
          onChanged:(v)=>_comment=v,
        ),
      ])),
      const SizedBox(height:14),

      ElevatedButton(
        onPressed:_saving?null:_save,
        style:ElevatedButton.styleFrom(backgroundColor:_green,foregroundColor:Colors.white,
          minimumSize:const Size.fromHeight(50),
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),
        child:Text(_saving?'Saving…':
          '✅ Save Marks ($_totalAwarded/${widget.test.totalMarks})',
          style:const TextStyle(fontWeight:FontWeight.w700,fontSize:15)),
      ),
      const SizedBox(height:32),
    ]),
  );
}