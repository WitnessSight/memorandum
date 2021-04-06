import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'card.dart';
import 'editor.dart';

void main() {
  runApp(MyApp());
}

///
/// 备忘录主要功能与细节
///
/// 1、实现了备忘录的新增、滑动删除(自选)、编辑、查找
/// 2、无备忘录或者未搜索到备忘录时，显示无备忘录
/// 3、可以前进或者后退时按钮才可用，可以保存50步。发生编辑后前进会清空
/// 4、在有标题时候才能够保存 (自选)
/// 5、选中标题或者内容时，可以触发保存按钮 （参考ios备忘录）
/// 6、在首页展示时只会用到存储内容的创建时间、标题和摘要
/// 7、搜索或者进入编辑页时会用到备忘录的完整内容
/// 8、光标颜色为橙色,统一配色
/// 9、卡片点击常规响应
///
class MyApp extends StatelessWidget {
  final SystemUiOverlayStyle _style =
      SystemUiOverlayStyle(statusBarColor: Colors.transparent);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(_style);

    return MaterialApp(
      title: '备忘录',
      home: MyHomePage(title: '备忘录'),
    );
  }
}

///
/// 备忘录首页
///
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SharedPreferences homeprefs;
  List<List<String>> memoContents;
  List<List<String>> originontents = [];
  TextEditingController textController = new TextEditingController();

  @override
  initState() {
    super.initState();
    getInfo();
  }

  Future<void> getInfo() async {
    if (homeprefs == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      homeprefs = prefs;
    }
    Set<String> msgs = homeprefs.getKeys();
    if (memoContents == null) {
      memoContents = [];
    }
    memoContents.clear();
    if (msgs.length > 0) {
      originontents.clear();
      for (String i in msgs) {
        if (i.contains("content")) {
          continue;
        }
        List<String> content = homeprefs.getStringList(i);
        originontents.add(content);
      }
      originontents.sort((left, right) => right[0].compareTo(left[0]));

      for (int i = 0; i < originontents.length; i++) {
        if (textController.text != "") {
          if (originontents[i][Editor.KEY_TITLE]
                  .contains(textController.text) ||
              originontents[i][Editor.KEY_SUMMARY]
                  .contains(textController.text)) {
            memoContents.add(originontents[i]);
          }
        } else {
          memoContents.add(originontents[i]);
        }
      }
    }else{
      originontents.clear();
    }
    setState(() {});
  }

  Future<void> refreshInfo(timeStamp) async {
    if (homeprefs == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      homeprefs = prefs;
    }
    List<String> changeItem = homeprefs.get(timeStamp);
    if (changeItem == null) {
      return;
    }
    bool contain = false;
    for (int i = 0; i < originontents.length; i++) {
      if (originontents[i][Editor.KEY_TIME] == timeStamp) {
        originontents[i][Editor.KEY_TITLE] = changeItem[Editor.KEY_TITLE];
        originontents[i][Editor.KEY_SUMMARY] = changeItem[Editor.KEY_SUMMARY];
        contain = true;
      }
    }
    if (memoContents == null) {
      memoContents = [];
    }
    for (int i = 0; i < memoContents.length; i++) {
      if (memoContents[i][Editor.KEY_TIME] == timeStamp) {
        memoContents[i][Editor.KEY_TITLE] = changeItem[Editor.KEY_TITLE];
        memoContents[i][Editor.KEY_SUMMARY] = changeItem[Editor.KEY_SUMMARY];
      }
    }
    if (!contain) {
      originontents.insert(0, changeItem);
      memoContents.insert(0, changeItem);
    }
  }

  _getRequests(val) async {
    refreshInfo(val);
  }

  void _addNewMemorandum() {
    Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => new EditorPage(
                  content: [
                    DateFormat("yyyy/MM/dd HH:mm:ss").format(DateTime.now()),
                    "",
                    ""
                  ],
                ))).then((val) => val != null ? _getRequests(val) : null);
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: new Scaffold(
          backgroundColor: Color(0xfff4f9f9),
          body: new SafeArea(
              child: new Container(
            padding: EdgeInsets.fromLTRB(25, 40, 25, 10),
            child: new Column(
              children: [
                new Row(
                  children: [
                    new Text("备忘录",
                        style: new TextStyle(
                            fontSize: 25.0, color: Colors.black87)),
                  ],
                ),
                new Card(
                  color: Color.fromRGBO(230, 237, 237, 1),
                  // elevation: 15.0,  //设置阴影
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(80.0))),
                  //设置圆角
                  child: new TextField(
                    cursorColor: Color(0xfff95928),
                    cursorHeight: 20,
                    keyboardType: TextInputType.text,
                    // style: TextStyle(textBaseline: TextBaseline.ideographic),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                        prefixIcon: Container(
                          color: Colors.transparent,
                          child: Icon(Icons.search,
                              size: 25, color: Color(0xaa9b9fa0)),
                        ),
                        hintStyle: TextStyle(fontSize: 20, height: 2),
                        hintText: "搜索",
                        border: InputBorder.none),
                    onChanged: _textSearch,
                    autofocus: false,
                    controller: textController,
                  ),
                ),
                memoContents == null
                    ? Container()
                    : ((memoContents.length > 0) ? memoList() : emptyList()),
              ],
            ),
          )),
          floatingActionButton: FloatingActionButton(
            onPressed: _addNewMemorandum,
            backgroundColor: Color.fromRGBO(251, 98, 30, 1),
            child: Icon(Icons.add),
          ),
        ));
  }

  Expanded emptyList() {
    return new Expanded(
        child: Center(
            child: new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          "assets/images/centerBook.png",
          width: 55,
          height: 55,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(0, 5, 5, 80),
          child: Text("没有备忘录",
              // textDirection: TextDirection.ltr,
              style: new TextStyle(fontSize: 12.0, color: Colors.black26)),
        )
      ],
    )));
  }

  Expanded memoList() {
    return Expanded(
        child: ListView.builder(
      itemCount: memoContents.length,
      itemBuilder: (context, index) {
        return new MemoCard(
            key: new Key(memoContents[index][0]), //DateTime.now().toString()
            content: memoContents[index],
            onTap: () {
              Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (context) =>
                              new EditorPage(content: memoContents[index])))
                  .then((val) => val != null ? _getRequests(val) : null);
              FocusScope.of(context).requestFocus(FocusNode());
            },
            ondelete: (param) {
              getInfo();
            });
      },
      shrinkWrap: true,
    ));
  }

  void _textSearch(String str) {
    memoContents.clear();
    for (int i = 0; i < originontents.length; i++) {
      if (originontents[i][Editor.KEY_SUMMARY].contains(str) ||
          originontents[i][Editor.KEY_TITLE].contains(str)) {
        memoContents.add(originontents[i]);
      }else{
        String innerContent = homeprefs.getString(originontents[i][Editor.KEY_TIME] + "-content");
        if(innerContent != null && innerContent.contains(str)){
          memoContents.add(originontents[i]);
        }
      }
    }
    setState(() {});
  }
}
