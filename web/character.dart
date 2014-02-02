// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library character;

import 'package:observe/observe.dart';
import 'utils.dart';

final COLLECTIONS = ["comics", "series", "stories", "events"];

class Character extends ChangeNotifier {
  String _name;
  String _thumb;
  String _pic;
  String _description;
  String _url;
  Map<String, int> _words;
  int _wordcount;

  bool _hidden = false;
  num _rating = 0;
  List<Map> _reasons = [];

  Character.fromJson(Map chardata) {
    _name = chardata["name"];
    _thumb = chardata["thumb"];
    _pic = chardata["pic"];
    _description = chardata["description"];
    _url = chardata["url"];
    _words = chardata["words"];
    _wordcount = chardata["wordcount"];
  }

  Character.fromMarvel(Map chardata) {
    List<String> matching = [];

    _name = chardata["name"];
    _thumb = chardata["thumbnail"]["path"] + "/portrait_small" + "." + chardata["thumbnail"]["extension"];
    _pic = chardata["thumbnail"]["path"] + "/portrait_xlarge" + "." + chardata["thumbnail"]["extension"];
    _description = chardata["description"];
    _url = chardata["urls"][0]["url"];

    matching.add(_name);
    matching.add(_description);

    COLLECTIONS.forEach((collection) {
      if (chardata.containsKey(collection) && chardata[collection].containsKey("items") && chardata[collection]["items"].length > 0) {
        chardata[collection]["items"].forEach((item) => matching.add(item["name"]));
      }
    });

    _words = create_wordmap(matching.join(" "));

    _wordcount = 0;
    _words.forEach((_, count) => _wordcount += count);
  }

  String get name => _name;

  void set name(String value) {
    _name = notifyPropertyChange(#name, _name, value);
  }

  String get thumb => _thumb;

  void set thumb(String value) {
    _thumb = notifyPropertyChange(#thumb, _thumb, value);
  }

  String get pic => _pic;

  void set pic(String value) {
    _pic = notifyPropertyChange(#pic, _pic, value);
  }

  String get description => _description;

  void set description(String value) {
    _description = notifyPropertyChange(#description, _description, value);
  }

  String get url => _url;

  void set url(String value) {
    _url = notifyPropertyChange(#url, _url, value);
  }

  bool get hidden => _hidden;

  void set hidden(bool value) {
    _hidden = notifyPropertyChange(#hidden, _hidden, value);
  }

  String get rating => _rating.toStringAsFixed(2);

  String toString() => "Character(name: $_name)";

  Map toJson() => {
    "name": _name,
    "thumb": _thumb,
    "pic": _pic,
    "description": _description,
    "url": _url,
    "words": _words,
    "wordcount": _wordcount
  };

  List<Map> get reasons => _reasons;

  int get wordcount => _wordcount;

  match(String word, int value) {
    if (_words.containsKey(word)) {
      _rating += _words[word] * value / _wordcount;
      _reasons.add({"word": word, "char_value": _words[word], "profile_value": value});
      _reasons.sort((a, b) => (b["char_value"] * b["profile_value"]).compareTo(a["char_value"] * a["profile_value"]));
    }
  }
}

class CharacterList extends ChangeNotifier {
  List<Character> _characters;
  bool _debug = false;

  CharacterList(this._characters);

  bool get debug => _debug;

  void set debug(bool value) {
    _debug = notifyPropertyChange(#debug, _debug, value);
  }

  List<Character> get characters => _characters;

  void set characters(List<Character> value) {
    _characters = notifyPropertyChange(#characters, _characters, value);
  }

  void add(Character char) {
    List<Character> old = new List.from(_characters);
    _characters.add(char);
    notifyPropertyChange(#characters, old, _characters);
  }

  List<Map> toJson() {
    var list = new List<Map>();
    for (var char in _characters) {
      list.add(char.toJson());
    }
    return list;
  }

  void match(Map<String, int> wordmap) {
    wordmap.forEach((word, count) {
      for (Character char in _characters) {
        char.match(word, count);
      }
    });
    _characters.sort((a, b) => b.rating.compareTo(a.rating));
    notifyPropertyChange(#characters, null, _characters);
  }
}