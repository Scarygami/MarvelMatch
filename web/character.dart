// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library character;

import 'package:observe/observe.dart';
import 'utils.dart';

class Character extends ChangeNotifier {
  String _name;
  String _thumb;
  String _pic;
  String _description;
  String _url;
  bool _hidden = false;
  int _rating = 0;
  List<String> _reason = [];
  List _words;

  Character(this._name, this._thumb, this._pic, this._description, this._url) {
    _words = create_wordlist(this._description);
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

  int get rating => _rating;

  String toString() => "Character(name: $_name)";

  Map toJson() => {
    "name": _name,
    "thumb": _thumb,
    "pic": _pic,
    "description": _description,
    "url": _url
  };

  String get reason => _reason.join(", ");

  match(String word, int value) {
    if (_words.any((w) => w["word"] == word)) {
      _rating += value;
      _reason.add(word);
    }
  }
}

class CharacterList extends ChangeNotifier {
  List<Character> _characters;

  CharacterList(this._characters);

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

  void match(List wordlist) {
    for (var word in wordlist) {
      for (Character char in _characters) {
        char.match(word["word"], word["count"]);
      }
    }
    _characters.sort((a, b) => b.rating.compareTo(a.rating));
    notifyPropertyChange(#characters, null, _characters);
  }
}