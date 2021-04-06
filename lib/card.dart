import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:memorandum/editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

///
/// 备忘录ListView的卡片
///
class MemoCard extends StatefulWidget {
  List<String> content;
  var tapbox;
  var onTap;
  var ondelete;

  MemoCard({Key key, this.content, this.onTap, this.ondelete})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    tapbox = _MemoCardState(content, onTap, ondelete);
    return tapbox;
  }
}

class _MemoCardState extends State<MemoCard> {
  bool _highlight = false;
  List<String> content;
  var onTap;
  var ondelete;

  _MemoCardState(memoContent, onTap, ondelete) {
    this.content = memoContent;
    this.onTap = onTap;
    this.ondelete = ondelete;
  }

  void refresh(fn) {
    super.setState(fn);
    content = fn;
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _highlight = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _highlight = false;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _highlight = false;
    });
  }

  void _handleTap() {
    this.onTap();
  }

  Widget build(BuildContext context) {
    return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTap: _handleTap,
        onTapCancel: _handleTapCancel,
        child: new Dismissible(
            key: new Key(content[Editor.KEY_TIME]),
            onDismissed: (direction) {
              SharedPreferences.getInstance().then((value) => {
                    value.remove(content[Editor.KEY_TIME]),
                    value.remove(content[Editor.KEY_TIME] + "-content"),
                    this.ondelete(content[Editor.KEY_TIME])
                  });
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(content[1],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                    new Container(
                      child: Text(content[2],
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 18.0, color: Colors.black45)),
                      margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    ),
                    Text(content[Editor.KEY_TIME],
                        textAlign: TextAlign.left,
                        style:
                            TextStyle(fontSize: 15.0, color: Colors.black45)),
                  ]),
              width: 200.0,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _highlight ? Color(0x99666666) : Color(0xffFEFFFF),
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
              ),
            )));
  }
}
