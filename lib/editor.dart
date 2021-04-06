import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int OPERATION_MAX_STEP = 50;

///
/// 数据结构 - 操作步骤
/// index: 操作结束后光标位置
/// operation：1代表增加，2代表删除
/// str: 变动的字符串
///
class Operation {
  int index;
  int operate;
  String str;

  Operation(int a, int b, String c) {
    index = a;
    operate = b;
    str = c;
  }
}

///
/// 栈结构
///
class Stack<E> {
  final List<E> _stack;
  final int capacity;

  Stack(this.capacity) : _stack = [];

  int getSize() {
    return _stack.length;
  }

  void push(E e) {
    if (_stack.length < capacity) {
      _stack.add(e);
    } else {
      _stack.removeAt(0);
      _stack.add(e);
    }
  }

  E pop() {
    if (_stack.isNotEmpty) {
      return _stack.removeLast();
    } else {
      return null;
    }
  }

  void clear() {
    _stack.clear();
  }
}

///
/// 适用两个栈结构来保存"前进"和"后退"操作
///
class Memory {
  Stack<Operation> stackBack = new Stack<Operation>(OPERATION_MAX_STEP);
  Stack<Operation> stackForward = new Stack<Operation>(OPERATION_MAX_STEP);

  void clear() {
    stackForward.clear();
  }
}

///
/// 备忘录编辑页面
///
class Editor extends State<EditorPage> {
  static const int KEY_TIME = 0;
  static const int KEY_TITLE = 1;
  static const int KEY_SUMMARY = 2;
  static const int KEY_CONTENT = 3;
  List<String> content = [];

  final TextEditingController titleController = new TextEditingController();
  final TextEditingController textController = new TextEditingController();
  Memory memory = new Memory();
  String lastStateString = "";
  bool saveable = false;
  bool backable = false;
  bool forwardable = false;

  Editor(param2) {
    content = param2;
    loadDada();
  }

  loadDada() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<String> msgs = prefs.getKeys();
    titleController.text = content[KEY_TITLE];
    textController.text = prefs.getString(content[KEY_TIME] + "-content");
    lastStateString = textController.text;
  }

  void _changeTap() {
    if (titleController.text.trim().length > 0) {
      setState(() {saveable = true;});
    }
  }

  void _titleFieldChanged(String str) {
    if (titleController.text.trim().length > 0) {
      setState(() {saveable = true;});
    }else{
      setState(() {saveable = false;});
    }
  }

  void _textFieldChanged(String str) {
    memory.clear();
    if (str.length > lastStateString.length) {
      int index = textController.selection.baseOffset.abs();
      int operation = 1;
      String temp =
          str.substring(index - (str.length - lastStateString.length), index);
      Operation o = new Operation(index, operation, temp);
      memory.stackBack.push(o);
    } else if (str.length < lastStateString.length) {
      int index = textController.selection.baseOffset.abs();
      int operation = 2;
      String temp = lastStateString.substring(
          index, index + (lastStateString.length - str.length));
      Operation o = new Operation(index, operation, temp);
      memory.stackBack.push(o);
    } else {}
    lastStateString = str;
    refreshButton();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          leading: IconButton(
            splashRadius: 20,
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context, content[KEY_TIME]),
          ),
          iconTheme: IconThemeData(
            color: Colors.black, //修改颜色
          ),
          backgroundColor: Color.fromRGBO(255, 255, 255, 1),
          elevation: 0,
          actions: [
            IconButton(
              splashRadius: 20,
              icon: Icon(Icons.arrow_back_ios_outlined),
              onPressed: backable ? backOperation : null,
            ),
            IconButton(
              splashRadius: 20,
              icon: Icon(Icons.arrow_forward_ios_outlined),
              onPressed: forwardable ? forwardOperation : null,
            ),
            saveable
                ? IconButton(
                    padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                    icon: Icon(Icons.save),
                    splashRadius: 20,
                    onPressed: saveable ? saveOperation : null,
                  )
                : Container(padding: EdgeInsets.fromLTRB(0, 0, 10, 0)),
          ],
        ),
        backgroundColor: Color.fromRGBO(254, 255, 255, 1),
        body: SingleChildScrollView(
            child: new Padding(
          padding: EdgeInsets.fromLTRB(25, 10, 25, 0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                controller: titleController,
                keyboardType: TextInputType.text,
                onTap: _changeTap,
                onChanged: _titleFieldChanged,
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    hintText: "标题",
                    border: InputBorder.none),
                autofocus: false,
              ),
              Text(content[KEY_TIME],
                  style:
                      new TextStyle(fontSize: 16.0, color: Color(0xff919494))),
              TextField(
                style: TextStyle(fontSize: 20, color: Color(0xff5e5f50)),
                controller: textController,
                keyboardType: TextInputType.multiline,
                onTap: _changeTap,
                onChanged: _textFieldChanged,
                maxLines: null,
                cursorColor: Color(0xffe96b36),
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                    hintText: "请输入内容",
                    border: InputBorder.none),
                autofocus: false,
              ),
              Container(
                height: 300,
                color: Colors.transparent,
              )
            ],
          ),
        )));
  }

  saveOperation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> list = [
      content[KEY_TIME],
      titleController.text,
      textController.text.length > 120
          ? textController.text.substring(0, 120)
          : textController.text
    ];

    prefs.setStringList(content[KEY_TIME], list).then((value) => {
          if (value)
            {
              prefs
                  .setString(
                      content[KEY_TIME] + "-content", textController.text)
                  .then((value) => {
                        if (value)
                          {
                            saveable = false,
                            FocusScope.of(context).requestFocus(FocusNode()),
                            setState(() {})
                          }
                      })
            }
        });
  }

  forwardOperation() {
    Operation temp = memory.stackForward.pop();
    if (temp == null) {
      return;
    }
    memory.stackBack.push(temp);
    if (temp.operate == 2) {
      textController.text = textController.text
          .replaceRange(temp.index, temp.index + temp.str.length, "");
      textController.selection =
          TextSelection(extentOffset: temp.index, baseOffset: temp.index);
    } else {
      textController.text =
          textController.text.substring(0, temp.index - temp.str.length) +
              temp.str +
              textController.text.substring(
                  temp.index - temp.str.length, textController.text.length);

      textController.selection =
          new TextSelection(extentOffset: temp.index, baseOffset: temp.index);
    }
    lastStateString = textController.text;
    refreshButton();
  }

  backOperation() {
    Operation temp = memory.stackBack.pop();
    if (temp == null) {
      saveable = false;
      setState(() {});
      return;
    }
    memory.stackForward.push(temp);
    if (temp.operate == 1) {
      textController.text = textController.text
          .replaceRange(temp.index - temp.str.length, temp.index, "");
      textController.selection = TextSelection(
          extentOffset: temp.index - temp.str.length,
          baseOffset: temp.index - temp.str.length);
    } else {
      textController.text = textController.text.substring(0, temp.index) +
          temp.str +
          textController.text.substring(temp.index, textController.text.length);

      textController.selection = new TextSelection(
          extentOffset: temp.index + temp.str.length,
          baseOffset: temp.index + temp.str.length);
    }
    lastStateString = textController.text;
    refreshButton();
  }

  void refreshButton() {
    if (memory.stackBack.getSize() > 0) {
      backable = true;
    } else {
      backable = false;
    }
    if (memory.stackForward.getSize() > 0) {
      forwardable = true;
    } else {
      forwardable = false;
    }
    if (memory.stackBack.getSize() > 0 || memory.stackForward.getSize() > 0) {
      if (titleController.text.trim().length > 0) {
        saveable = true;
      }
    } else {
      saveable = false;
    }
    setState(() {});
  }
}

class EditorPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return Editor(content);
  }

  EditorPage({Key key, this.content}) : super(key: key);
  final List<String> content;
}
