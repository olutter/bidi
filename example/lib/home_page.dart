import 'package:material_ui/material_ui.dart';
import 'package:bidi/bidi.dart' as bidi;
import 'package:flutter/services.dart';

const _initialText =
    'چو چپ راست کرد و خم آورد راست، خروش از خم چرخ چاچی بخاست.';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _paragraphs = <bidi.Paragraph>[];
  bool _spacing = true;

  void _onChanged(String value) {
    _paragraphs.clear();

    if (value.isNotEmpty) {
      final bidiText = bidi.BidiString.fromLogical(value);
      _paragraphs.addAll(bidiText.paragraphs);
    }

    setState(() {});
  }

  @override
  void initState() {
    _onChanged(_initialText);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bidi'),
        actions: [
          IconButton(
            icon: Icon(Icons.space_bar),
            onPressed: () {
              setState(() {
                _spacing = !_spacing;
              });
            },
          )
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  initialValue: _initialText,
                  maxLines: 8,
                  onChanged: _onChanged,
                ),
              ),
              ..._paragraphs.map(
                (p) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    runSpacing: 8,
                    spacing: _spacing ? 8 : 0,
                    children: p.bidiText.reversed
                        .map(
                          (e) => InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: String.fromCharCode(e),
                                ),
                              );
                            },
                            hoverColor: Colors.pink,
                            focusColor: Colors.green,
                            splashColor: Colors.amber,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: _spacing ? 2.0 : 0,
                              ),
                              child: Text(
                                String.fromCharCode(e),
                                textScaler: TextScaler.linear(2),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
