import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/api_service.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────
class _C {
  static const bg       = Color(0xFF0D1117);
  static const surface  = Color(0xFF161B22);
  static const surface2 = Color(0xFF21262D);
  static const border   = Color(0xFF30363D);
  static const text     = Color(0xFFE6EDF3);
  static const text2    = Color(0xFF8B949E);
  static const text3    = Color(0xFF6E7681);
  static const green    = Color(0xFF2EA043);
  static const greenL   = Color(0xFF3FB950);
  static const greenBg  = Color(0xFF1A3A2A);
  static const blue     = Color(0xFF58A6FF);
  static const blueBg   = Color(0xFF1A2A3A);
  static const purple   = Color(0xFFA371F7);
  static const purpleBg = Color(0xFF2A1A3A);
  static const red      = Color(0xFFF85149);
  static const redBg    = Color(0xFF3D1A1A);
  static const yellow   = Color(0xFFE3B341);
  static const border2  = Color(0xFF21262D);
}

const Map<String, Color> _subjectColors = {
  'Biology':         Color(0xFF2EA043),
  'Mathematics':     Color(0xFF1F6FEB),
  'Chemistry':       Color(0xFFA371F7),
  'Physics':         Color(0xFFF0883E),
  'English':         Color(0xFFE3B341),
  'Geography':       Color(0xFF58A6FF),
  'History':         Color(0xFFDA3633),
  'Civic Education': Color(0xFF56D364),
  'Computer Studies':Color(0xFF79C0FF),
};

// ─── Data ─────────────────────────────────────────────────────────────────────
const List<String> _subjects = [
  'Biology','Mathematics','English','Physics','Chemistry','History',
  'Civic Education','Computer Studies','Agriculture','Business Studies',
  'Home Economics','Chichewa','French',
];
const List<String> _forms     = ['Form 1','Form 2','Form 3','Form 4'];
const List<String> _durations = ['15 min','30 min','45 min','60 min','90 min','120 min'];

// ─── Models ───────────────────────────────────────────────────────────────────
class _Question {
  String id;
  String text;
  List<String> options;
  int answer;
  _Question({required this.id, this.text='', List<String>? options, this.answer=0})
      : options = options ?? ['','','',''];
  _Question copyWith({String? id,String? text,List<String>? options,int? answer}) =>
      _Question(id:id??this.id, text:text??this.text, options:options??List.from(this.options), answer:answer??this.answer);
  Map<String,dynamic> toJson() => {'id':id,'text':text,'options':options,'answer':answer};
}

class _Quiz {
  String title, subject, form, duration, description, visibility, schoolId;
  List<_Question> questions;
  _Quiz({this.title='',this.subject='Biology',this.form='Form 1',this.duration='30 min',
         this.description='',this.visibility='PUBLIC',this.schoolId='',List<_Question>? questions})
      : questions = questions ?? [_blankQ()];
}

_Question _blankQ() => _Question(id:'${DateTime.now().microsecondsSinceEpoch}-${Object().hashCode}');
_Quiz _blankQuiz() => _Quiz();

// ─── Main Screen ──────────────────────────────────────────────────────────────
class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});
  @override State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  String _view  = 'create'; // create | saved
  String _mode  = 'online';
  _Quiz  _quiz  = _blankQuiz();
  bool   _saving      = false;
  bool   _loadingList = false;
  List<Map<String,dynamic>> _savedQuizzes = [];
  List<Map<String,dynamic>> _schools      = [];
  Map<String,dynamic>? _toast;

  @override void initState() { super.initState(); _loadQuizzes(); _fetchSchools(); }

  Future<String?> _token() async => (await SharedPreferences.getInstance()).getString('accessToken');
  Future<Map<String,String>> _headers() async {
    final t = await _token();
    return {'Content-Type':'application/json', if (t!=null) 'Authorization':'Bearer $t'};
  }

  void _showToast(String msg, {String type='success'}) {
    setState(() => _toast = {'msg':msg,'type':type});
    Future.delayed(const Duration(milliseconds:3500), () { if (mounted) setState(() => _toast=null); });
  }

  Future<void> _loadQuizzes() async {
    setState(() => _loadingList=true);
    try {
      final res = await http.get(Uri.parse('$kApiBase/quizzes/mine'), headers: await _headers());
      if (res.statusCode < 300) setState(() => _savedQuizzes = List<Map<String,dynamic>>.from(jsonDecode(res.body)));
    } catch (_) {}
    finally { setState(() => _loadingList=false); }
  }

  Future<void> _fetchSchools() async {
    try {
      final res = await http.get(Uri.parse('$kApiBase/school'), headers: await _headers());
      if (res.statusCode < 300) setState(() => _schools = List<Map<String,dynamic>>.from(jsonDecode(res.body)));
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    if (_quiz.title.trim().isEmpty)                                        { _showToast('Please enter a quiz title.', type:'error'); return; }
    if (_quiz.questions.any((q) => q.text.trim().isEmpty))                 { _showToast('All questions must have text.', type:'error'); return; }
    if (_quiz.questions.any((q) => q.options.any((o) => o.trim().isEmpty))){ _showToast('Please fill in all answer options.', type:'error'); return; }
    setState(() => _saving=true);
    try {
      // 1 — Save the quiz
      final body = jsonEncode({
        'title':_quiz.title,'subject':_quiz.subject,'form':_quiz.form,
        'duration':_quiz.duration,'description':_quiz.description,
        'visibility':_quiz.visibility,'schoolId':_quiz.schoolId,
        'mode':_mode,'status':'published',
        'questions':_quiz.questions.map((q) => q.toJson()).toList(),
      });
      final res = await http.post(Uri.parse('$kApiBase/quizzes'), headers: await _headers(), body: body);
      if (res.statusCode >= 300) {
        final d = jsonDecode(res.body); throw Exception(d['message'] ?? 'Failed to save quiz');
      }
      final saved = jsonDecode(res.body) as Map<String,dynamic>;
      setState(() { _savedQuizzes = [saved,..._savedQuizzes]; _quiz = _blankQuiz(); _view = 'saved'; });

      // 2 — For offline quizzes, request PDF and open the download URL
      if (_mode == 'offline') {
        _showToast('Quiz saved! Generating PDF…');
        await _exportPdf(saved['id']);
      } else {
        _showToast('Quiz "${saved['title']}" saved successfully!');
      }
    } catch (e) { _showToast(e.toString(), type:'error'); }
    finally { setState(() => _saving=false); }
  }

  Future<void> _exportPdf(dynamic quizId) async {
    try {
      final res = await http.get(
        Uri.parse('$kApiBase/quizzes/$quizId/export/pdf'),
        headers: await _headers(),
      );
      if (res.statusCode >= 300) {
        final d = jsonDecode(res.body);
        throw Exception(d['message'] ?? 'PDF export failed (\${res.statusCode})');
      }
      final data = jsonDecode(res.body) as Map<String,dynamic>;
      final url  = data['url']?.toString() ?? '';
      if (url.isEmpty) throw Exception('No download URL returned');

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showToast('PDF ready! Opening download…', type: 'success');
      } else {
        throw Exception('Could not open: \$url');
      }
    } catch (e) {
      _showToast('PDF error: \$e', type: 'error');
    }
  }

  Future<void> _deleteQuiz(dynamic id) async {
    try {
      final res = await http.delete(Uri.parse('$kApiBase/quizzes/$id'), headers: await _headers());
      if (res.statusCode >= 300) throw Exception('Failed to delete quiz');
      setState(() => _savedQuizzes = _savedQuizzes.where((q) => q['id'] != id).toList());
      _showToast('Quiz deleted.');
    } catch (e) { _showToast(e.toString(), type:'error'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          SafeArea(child: _buildBody()),
          if (_toast != null) _buildToast(),
        ],
      ),
    );
  }

  Widget _buildToast() {
    final isErr = _toast!['type'] == 'error';
    return Positioned(
      top: 16, right: 16, left: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal:16,vertical:12),
          decoration: BoxDecoration(
            color: isErr ? _C.redBg : _C.greenBg,
            border: Border.all(color: isErr ? _C.red : _C.green),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color:Colors.black.withValues(alpha:0.4),blurRadius:12)],
          ),
          child: Row(children:[
            Text(isErr?'⚠️ ':'✅ '),
            Expanded(child: Text(_toast!['msg'], style:TextStyle(color:isErr?_C.red:_C.green,fontWeight:FontWeight.w600,fontSize:13))),
          ]),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          _buildHeader(),
          const SizedBox(height:16),
          if (_view=='create')    _buildCreateView(),
          if (_view=='saved')     _buildSavedView(),
          const SizedBox(height:32),
        ]),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final tabs = [
      {'key':'create',   'label':'✏️ Create'},
      {'key':'saved',    'label':'📋 My Quizzes${_savedQuizzes.isNotEmpty?" (${_savedQuizzes.length})":""}'},
    ];
    return Container(
      width:double.infinity,
      padding:const EdgeInsets.all(20),
      decoration:BoxDecoration(
        color:_C.greenBg, border:Border.all(color:_C.green),
        borderRadius:BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        const Text('✏️ Quiz Management', style:TextStyle(color:_C.text,fontWeight:FontWeight.bold,fontSize:20)),
        const SizedBox(height:4),
        const Text('Build quizzes and track student progress.', style:TextStyle(color:_C.text2,fontSize:13)),
        const SizedBox(height:16),
        Row(children: tabs.map((t) {
          final active = _view == t['key'];
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: t==tabs.last?0:8),
            child: GestureDetector(
              onTap: () { setState(() => _view=t['key']!); if(t['key']=='saved') _loadQuizzes(); },
              child: Container(
                padding:const EdgeInsets.symmetric(vertical:8),
                decoration:BoxDecoration(
                  color:active?_C.green:_C.surface2,
                  border:Border.all(color:active?_C.green:_C.border),
                  borderRadius:BorderRadius.circular(6),
                ),
                child:Text(t['label']!,textAlign:TextAlign.center,
                  style:TextStyle(color:active?Colors.white:_C.text2,fontWeight:FontWeight.w600,fontSize:11)),
              ),
            ),
          ));
        }).toList()),
      ]),
    );
  }

  // ── Create View ────────────────────────────────────────────────────────────
  Widget _buildCreateView() {
    return Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      // Mode tabs
      Row(children:[
        Expanded(child:_tabBtn('🌐 Online Quiz', _mode=='online', () => setState(()=>_mode='online'))),
        const SizedBox(width:8),
        Expanded(child:_tabBtn('📄 Offline / Printable', _mode=='offline', () => setState(()=>_mode='offline'))),
      ]),
      const SizedBox(height:12),
      // Mode banner
      Container(
        width:double.infinity,
        padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),
        decoration:BoxDecoration(
          color:_mode=='online'?_C.blueBg:_C.purpleBg,
          border:Border.all(color:_mode=='online'?_C.blue:_C.purple),
          borderRadius:BorderRadius.circular(8),
        ),
        child:Text(
          _mode=='online'
            ? '🌐 Online quizzes are taken digitally via a shared link.'
            : '📄 Offline quizzes can be downloaded as PDF and printed for class.',
          style:TextStyle(color:_mode=='online'?_C.blue:_C.purple,fontSize:12),
        ),
      ),
      const SizedBox(height:16),
      _buildQuizDetails(),
      const SizedBox(height:16),
      _buildQuestionsSection(),
      const SizedBox(height:16),
      _buildSaveBar(),
    ]);
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap:onTap,
      child:Container(
        padding:const EdgeInsets.symmetric(vertical:12),
        decoration:BoxDecoration(
          color:active?_C.green:_C.surface,
          border:Border.all(color:active?_C.green:_C.border2),
          borderRadius:BorderRadius.circular(8),
        ),
        child:Text(label,textAlign:TextAlign.center,
          style:TextStyle(color:active?Colors.white:_C.text2,fontWeight:FontWeight.w600,fontSize:13)),
      ),
    );
  }

  Widget _buildQuizDetails() {
    return _card(
      title:'📝 Quiz Details',
      children:[
        _label('Quiz Title *'),
        _textField(hint:'e.g. Cell Biology Quiz — Week 3', value:_quiz.title,
          onChanged:(v) => setState(()=>_quiz.title=v)),
        const SizedBox(height:12),
        _label('Subject'),
        _dropdown(value:_quiz.subject, items:_subjects,
          onChanged:(v)=>setState(()=>_quiz.subject=v??_quiz.subject)),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            _label('Form / Class'),
            _dropdown(value:_quiz.form, items:_forms,
              onChanged:(v)=>setState(()=>_quiz.form=v??_quiz.form)),
          ])),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            _label('Duration'),
            _dropdown(value:_quiz.duration, items:_durations,
              onChanged:(v)=>setState(()=>_quiz.duration=v??_quiz.duration)),
          ])),
        ]),
        const SizedBox(height:12),
        _label('Visibility'),
        _dropdown(
          value:_quiz.visibility,
          items:const ['PUBLIC','PRIVATE'],
          display:(v)=>v=='PUBLIC'?'Public (All Students)':'Private (School Only)',
          onChanged:(v)=>setState(()=>_quiz.visibility=v??_quiz.visibility),
        ),
        if (_quiz.visibility=='PRIVATE') ...[
          const SizedBox(height:12),
          _label('School'),
          _dropdown(
            value:_quiz.schoolId.isEmpty && _schools.isNotEmpty ? '' : _quiz.schoolId,
            items:['',..._schools.map((s)=>s['id'].toString())],
            display:(v){
              if (v.isEmpty) return 'Select school';
              final s = _schools.firstWhere((s)=>s['id'].toString()==v, orElse:()=>{});
              return s['name']?.toString() ?? v;
            },
            onChanged:(v)=>setState(()=>_quiz.schoolId=v??''),
          ),
        ],
        const SizedBox(height:12),
        _label('Description (optional)'),
        _textField(hint:'Brief instructions or topic overview...', value:_quiz.description,
          maxLines:2, onChanged:(v)=>setState(()=>_quiz.description=v)),
      ],
    );
  }

  Widget _buildQuestionsSection() {
    return Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
        Text('❓ Questions (${_quiz.questions.length})',
          style:const TextStyle(color:_C.text,fontWeight:FontWeight.bold,fontSize:14)),
        _smallBtn('+ Add Question', onTap:_addQuestion),
      ]),
      const SizedBox(height:12),
      ...List.generate(_quiz.questions.length, (i) =>
        _QuestionCard(
          q:_quiz.questions[i], index:i,
          canRemove:_quiz.questions.length>1,
          onChange:(updated) => setState(()=>_quiz.questions[i]=updated),
          onRemove:() => setState(()=>_quiz.questions.removeAt(i)),
        ),
      ),
      const SizedBox(height:8),
      GestureDetector(
        onTap:_addQuestion,
        child:Container(
          width:double.infinity,
          padding:const EdgeInsets.symmetric(vertical:16),
          decoration:BoxDecoration(
            border:Border.all(color:_C.border2,style:BorderStyle.solid),
            borderRadius:BorderRadius.circular(8),
            color:Colors.transparent,
          ),
          child:const Text('+ Add Another Question',textAlign:TextAlign.center,
            style:TextStyle(color:_C.text3,fontWeight:FontWeight.w600,fontSize:13)),
        ),
      ),
    ]);
  }

  void _addQuestion() => setState(()=>_quiz.questions.add(_blankQ()));

  Widget _buildSaveBar() {
    return Container(
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(
        color:_C.surface, border:Border.all(color:_C.border2),
        borderRadius:BorderRadius.circular(8),
      ),
      child:Column(children:[
        Row(children:[
          Text('${_quiz.questions.length}', style:const TextStyle(color:_C.text,fontWeight:FontWeight.bold,fontSize:13)),
          Text(' question${_quiz.questions.length!=1?"s":""} · ', style:const TextStyle(color:_C.text3,fontSize:13)),
          Text(_quiz.duration, style:const TextStyle(color:_C.text,fontWeight:FontWeight.bold,fontSize:13)),
          Text(' · ', style:const TextStyle(color:_C.text3,fontSize:13)),
          Text(_mode=='online'?'🌐 Online':'📄 Offline',
            style:TextStyle(color:_mode=='online'?_C.blue:_C.purple,fontWeight:FontWeight.w600,fontSize:13)),
        ]),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:OutlinedButton(
            onPressed:()=>setState(()=>_quiz=_blankQuiz()),
            style:OutlinedButton.styleFrom(
              foregroundColor:_C.text2,side:const BorderSide(color:_C.border),
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(6)),
              padding:const EdgeInsets.symmetric(vertical:12),
            ),
            child:const Text('Reset'),
          )),
          const SizedBox(width:12),
          Expanded(flex:2,child:ElevatedButton(
            onPressed:_saving?null:_handleSave,
            style:ElevatedButton.styleFrom(
              backgroundColor:_C.green,foregroundColor:Colors.white,
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(6)),
              padding:const EdgeInsets.symmetric(vertical:12),
              disabledBackgroundColor:_C.surface2,
            ),
            child:Text(_saving?'Saving...':_mode=='online'?'💾 Save & Publish':'💾 Save & Export',
              style:const TextStyle(fontWeight:FontWeight.w600)),
          )),
        ]),
      ]),
    );
  }

  // ── Saved Quizzes View ─────────────────────────────────────────────────────
  Widget _buildSavedView() {
    return Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
        RichText(text:TextSpan(children:[
          const TextSpan(text:'📋 My Quizzes ',style:TextStyle(color:_C.text,fontWeight:FontWeight.bold,fontSize:17)),
          TextSpan(text:'(${_savedQuizzes.length} total)',style:const TextStyle(color:_C.text3,fontSize:13)),
        ])),
        ElevatedButton(
          onPressed:()=>setState(()=>_view='create'),
          style:ElevatedButton.styleFrom(backgroundColor:_C.green,foregroundColor:Colors.white,
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(6)),
            padding:const EdgeInsets.symmetric(horizontal:14,vertical:8)),
          child:const Text('+ New Quiz',style:TextStyle(fontWeight:FontWeight.w600,fontSize:13)),
        ),
      ]),
      const SizedBox(height:16),
      if (_loadingList)
        const Center(child:Padding(padding:EdgeInsets.all(48),child:CircularProgressIndicator(color:_C.green)))
      else if (_savedQuizzes.isEmpty)
        Container(
          width:double.infinity,
          padding:const EdgeInsets.symmetric(vertical:64),
          decoration:BoxDecoration(color:_C.surface,border:Border.all(color:_C.border2),borderRadius:BorderRadius.circular(12)),
          child:Column(children:[
            const Text('📭',style:TextStyle(fontSize:40)),
            const SizedBox(height:12),
            const Text('No quizzes created yet.',style:TextStyle(color:_C.text3,fontSize:13)),
            const SizedBox(height:16),
            ElevatedButton(onPressed:()=>setState(()=>_view='create'),
              style:ElevatedButton.styleFrom(backgroundColor:_C.green,foregroundColor:Colors.white,
                shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(6))),
              child:const Text('Create Your First Quiz')),
          ]),
        )
      else
        ...(_savedQuizzes.map((q) => _SavedQuizCard(quiz:q, onDelete:_deleteQuiz))),
    ]);
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _card({required String title, required List<Widget> children}) => Container(
    width:double.infinity,
    padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(color:_C.surface,border:Border.all(color:_C.border2),borderRadius:BorderRadius.circular(8)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(color:_C.text,fontWeight:FontWeight.bold,fontSize:14)),
      const SizedBox(height:14),
      ...children,
    ]),
  );

  Widget _label(String t) => Padding(
    padding:const EdgeInsets.only(bottom:6),
    child:Text(t,style:const TextStyle(color:_C.text3,fontSize:12)),
  );

  Widget _textField({required String hint,required String value,int maxLines=1,required ValueChanged<String> onChanged}) =>
    TextFormField(
      initialValue:value, maxLines:maxLines, onChanged:onChanged,
      style:const TextStyle(color:_C.text,fontSize:13),
      decoration:InputDecoration(
        hintText:hint,hintStyle:const TextStyle(color:_C.text3),
        filled:true,fillColor:_C.bg,
        contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:_C.border2)),
        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:_C.border2)),
        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:_C.green,width:1.5)),
      ),
    );

  Widget _dropdown({required String value,required List<String> items,
      String Function(String)? display,required ValueChanged<String?> onChanged}) =>
    DropdownButtonFormField<String>(
      value:items.contains(value)?value:items.first,
      onChanged:onChanged,
      dropdownColor:_C.surface,
      style:const TextStyle(color:_C.text,fontSize:13),
      decoration:InputDecoration(
        filled:true,fillColor:_C.bg,
        contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:_C.border2)),
        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:_C.border2)),
        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:_C.green,width:1.5)),
      ),
      items:items.map((i)=>DropdownMenuItem(value:i,child:Text(display!=null?display(i):i))).toList(),
    );

  Widget _smallBtn(String label,{required VoidCallback onTap}) => GestureDetector(
    onTap:onTap,
    child:Container(
      padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),
      decoration:BoxDecoration(color:_C.surface2,border:Border.all(color:_C.border),borderRadius:BorderRadius.circular(6)),
      child:Text(label,style:const TextStyle(color:_C.text,fontWeight:FontWeight.w600,fontSize:12)),
    ),
  );
}

// ─── Question Card ────────────────────────────────────────────────────────────
class _QuestionCard extends StatelessWidget {
  final _Question q;
  final int index;
  final bool canRemove;
  final ValueChanged<_Question> onChange;
  final VoidCallback onRemove;
  const _QuestionCard({required this.q,required this.index,required this.canRemove,required this.onChange,required this.onRemove});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      margin:const EdgeInsets.only(bottom:12),
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(color:_C.bg,border:Border.all(color:_C.border2),borderRadius:BorderRadius.circular(8)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
            decoration:BoxDecoration(color:_C.greenBg,borderRadius:BorderRadius.circular(4)),
            child:Text('Q${index+1}',style:const TextStyle(color:_C.green,fontWeight:FontWeight.bold,fontSize:11))),
          if (canRemove) GestureDetector(onTap:onRemove,
            child:const Text('✕ Remove',style:TextStyle(color:_C.red,fontSize:12))),
        ]),
        const SizedBox(height:10),
        TextFormField(
          initialValue:q.text,
          maxLines:2,
          onChanged:(v)=>onChange(q.copyWith(text:v)),
          style:const TextStyle(color:_C.text,fontSize:13),
          decoration:InputDecoration(
            hintText:'Enter your question here...',hintStyle:const TextStyle(color:_C.text3),
            filled:true,fillColor:_C.surface,
            contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:_C.border2)),
            enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:_C.border2)),
            focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:_C.green,width:1.5)),
          ),
        ),
        const SizedBox(height:10),
        const Text('Click the circle to mark correct answer',style:TextStyle(color:_C.text3,fontSize:11)),
        const SizedBox(height:8),
        ...List.generate(q.options.length, (i) {
          final isCorrect = q.answer==i;
          return Padding(
            padding:const EdgeInsets.only(bottom:8),
            child:Row(children:[
              GestureDetector(
                onTap:()=>onChange(q.copyWith(answer:i)),
                child:Container(
                  width:20,height:20,
                  decoration:BoxDecoration(
                    shape:BoxShape.circle,
                    color:isCorrect?_C.green:Colors.transparent,
                    border:Border.all(color:isCorrect?_C.green:_C.border,width:2),
                  ),
                  child:isCorrect?const Center(child:Text('✓',style:TextStyle(color:Colors.white,fontSize:10))):null,
                ),
              ),
              const SizedBox(width:8),
              Expanded(child:TextFormField(
                initialValue:q.options[i],
                onChanged:(v){
                  final opts=List<String>.from(q.options); opts[i]=v;
                  onChange(q.copyWith(options:opts));
                },
                style:const TextStyle(color:_C.text,fontSize:13),
                decoration:InputDecoration(
                  hintText:'Option ${String.fromCharCode(65+i)}',hintStyle:const TextStyle(color:_C.text3),
                  filled:true,fillColor:_C.surface,
                  contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
                  border:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:BorderSide(color:isCorrect?_C.green:_C.border2)),
                  enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:BorderSide(color:isCorrect?_C.green:_C.border2)),
                  focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(6),borderSide:const BorderSide(color:_C.green,width:1.5)),
                ),
              )),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─── Saved Quiz Card ──────────────────────────────────────────────────────────
class _SavedQuizCard extends StatefulWidget {
  final Map<String,dynamic> quiz;
  final Future<void> Function(dynamic) onDelete;
  const _SavedQuizCard({required this.quiz,required this.onDelete});
  @override State<_SavedQuizCard> createState() => _SavedQuizCardState();
}
class _SavedQuizCardState extends State<_SavedQuizCard> {
  bool _expanded  = false;
  bool _pdfLoading = false;

  String _fmtDate(dynamic d) {
    if (d==null) return '—';
    try {
      final dt = DateTime.parse(d.toString());
      return '${_months[dt.month-1]} ${dt.day}, ${dt.year}';
    } catch(_) { return '—'; }
  }
  static const _months=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  Future<void> _downloadPdf(dynamic quizId) async {
    setState(() => _pdfLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      final res = await http.get(
        Uri.parse('$kApiBase/quizzes/$quizId/export/pdf'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode >= 300) {
        final d = jsonDecode(res.body);
        throw Exception(d['message'] ?? 'Export failed');
      }
      final data = jsonDecode(res.body) as Map<String,dynamic>;
      final url  = data['url']?.toString() ?? '';
      if (url.isEmpty) throw Exception('No URL returned');
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot open URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF error: $e'),
          backgroundColor: _C.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final q = widget.quiz;
    final isOnline = q['mode']=='online';
    final modeColor = isOnline?_C.blue:_C.purple;
    final modeBg    = isOnline?_C.blueBg:_C.purpleBg;
    final qs        = (q['questions'] as List?)??[];

    return Container(
      margin:const EdgeInsets.only(bottom:12),
      decoration:BoxDecoration(color:_C.surface,border:Border.all(color:_C.border2),borderRadius:BorderRadius.circular(8)),
      child:Column(children:[
        Padding(
          padding:const EdgeInsets.all(16),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              _chip(isOnline?'🌐 Online':'📄 Offline', modeColor, modeBg),
              const SizedBox(width:6),
              _chip(q['subject']?.toString()??'', _C.green, _C.greenBg),
              const SizedBox(width:6),
              _chip(q['form']?.toString()??'', _C.text3, _C.surface2, border:_C.border),
              const Spacer(),
              GestureDetector(
                onTap:()=>widget.onDelete(q['id']),
                child:const Text('🗑 Delete',style:TextStyle(color:_C.red,fontSize:12)),
              ),
            ]),
            const SizedBox(height:10),
            Text(q['title']?.toString()??'',style:const TextStyle(color:_C.text,fontWeight:FontWeight.w600,fontSize:14)),
            if ((q['description']?.toString()??'').isNotEmpty) ...[
              const SizedBox(height:4),
              Text(q['description'].toString(),style:const TextStyle(color:_C.text3,fontSize:12)),
            ],
            const SizedBox(height:10),
            Row(children:[
              Text('❓ ${qs.length} questions',style:const TextStyle(color:_C.text3,fontSize:12)),
              const SizedBox(width:12),
              Text('⏱ ${q['duration']??''}',style:const TextStyle(color:_C.text3,fontSize:12)),
              const SizedBox(width:12),
              Text('📅 ${_fmtDate(q['createdAt'])}',style:const TextStyle(color:_C.text3,fontSize:12)),
            ]),
            const SizedBox(height:12),
            Row(children:[
              GestureDetector(
                onTap:()=>setState(()=>_expanded=!_expanded),
                child:Container(
                  padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),
                  decoration:BoxDecoration(color:_C.surface2,border:Border.all(color:_C.border),borderRadius:BorderRadius.circular(6)),
                  child:Text(_expanded?'▲ Hide':'▼ Preview',
                    style:const TextStyle(color:_C.text,fontWeight:FontWeight.w600,fontSize:12)),
                ),
              ),
              if (!isOnline) ...[
                const SizedBox(width:8),
                GestureDetector(
                  onTap: _pdfLoading ? null : () => _downloadPdf(q['id']),
                  child: Container(
                    padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),
                    decoration:BoxDecoration(
                      color: _pdfLoading ? _C.surface2 : _C.purpleBg,
                      border:Border.all(color: _pdfLoading ? _C.border : _C.purple),
                      borderRadius:BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize:MainAxisSize.min, children:[
                      if (_pdfLoading)
                        const SizedBox(width:12,height:12,child:CircularProgressIndicator(strokeWidth:1.5,color:_C.purple))
                      else
                        const Text('📄',style:TextStyle(fontSize:12)),
                      const SizedBox(width:5),
                      Text(
                        _pdfLoading ? 'Generating…' : 'Download PDF',
                        style:TextStyle(color:_pdfLoading?_C.text3:_C.purple,fontWeight:FontWeight.w600,fontSize:12),
                      ),
                    ]),
                  ),
                ),
              ],
            ]),
          ]),
        ),
        if (_expanded)
          Container(
            width:double.infinity,
            padding:const EdgeInsets.all(16),
            decoration:const BoxDecoration(
              color:_C.bg,
              border:Border(top:BorderSide(color:_C.border2)),
              borderRadius:BorderRadius.only(bottomLeft:Radius.circular(8),bottomRight:Radius.circular(8)),
            ),
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children:List.generate(qs.length,(i){
                final qItem = qs[i] as Map<String,dynamic>;
                final opts  = (qItem['options'] as List?)??[];
                final ans   = qItem['answer'] as int? ?? 0;
                return Padding(
                  padding:const EdgeInsets.only(bottom:16),
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text('Q${i+1}. ${qItem['text']?.toString()??''}',
                      style:const TextStyle(color:_C.text,fontWeight:FontWeight.w600,fontSize:13)),
                    const SizedBox(height:6),
                    Wrap(
                      spacing:6,runSpacing:4,
                      children:List.generate(opts.length,(oi){
                        final isAns=ans==oi;
                        return Container(
                          padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
                          decoration:BoxDecoration(
                            color:isAns?_C.greenBg:Colors.transparent,
                            borderRadius:BorderRadius.circular(4),
                          ),
                          child:Text('${String.fromCharCode(65+oi)}. ${opts[oi]}${isAns?" ✓":""}',
                            style:TextStyle(color:isAns?_C.green:_C.text3,
                              fontWeight:isAns?FontWeight.bold:FontWeight.normal,fontSize:12)),
                        );
                      }),
                    ),
                  ]),
                );
              }),
            ),
          ),
      ]),
    );
  }

  Widget _chip(String label, Color color, Color bg, {Color? border}) => Container(
    padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
    decoration:BoxDecoration(color:bg,border:Border.all(color:border??bg),borderRadius:BorderRadius.circular(4)),
    child:Text(label,style:TextStyle(color:color,fontWeight:FontWeight.bold,fontSize:11)),
  );
}