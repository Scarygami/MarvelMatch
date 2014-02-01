import 'dart:html';
import 'dart:convert';
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:template_binding/template_binding.dart' show templateBind;

import "package:google_plus_v1_api/plus_v1_api_browser.dart" as pluslib;
import "package:google_plus_v1_api/plus_v1_api_client.dart" as pluslib_client;
import "package:google_oauth2_client/google_oauth2_browser.dart" as oauth;

import 'character.dart';
import 'utils.dart';

export 'package:polymer/init.dart';

CharacterList characters = new CharacterList([]);

oauth.GoogleOAuth2 auth;
pluslib.Plus plus;

final CLIENT_ID = "<your_google_client_id>";
final MARVEL_DEV_KEY = "<your_marvel_dev_key>";
final SCOPES = [pluslib.Plus.PLUS_LOGIN_SCOPE];

Future<bool> fetchChars({offset: 0}) {
  var path = "https://gateway.marvel.com/v1/public/characters?limit=100&offset=${offset}&apikey=$MARVEL_DEV_KEY";
  var completer = new Completer<bool>();
  HttpRequest.getString(path)
    .then((String fileContents) {
      List chars = [];
      Map data = JSON.decode(fileContents);
      if (data.containsKey("data") && data["data"].containsKey("results") && data["data"]["results"].length > 0) {
        for (var chardata in data["data"]["results"]) {
          if (chardata.containsKey("description")) {
            if (chardata["description"] != "") {
              if (chardata.containsKey("thumbnail") && chardata["thumbnail"].containsKey("path")) {
                if (chardata.containsKey("urls") && chardata["urls"].length > 0) {
                  var thumb = chardata["thumbnail"]["path"] + "/portrait_small" + "." + chardata["thumbnail"]["extension"];
                  var pic = chardata["thumbnail"]["path"] + "/portrait_xlarge" + "." + chardata["thumbnail"]["extension"];
                  characters.add(new Character(chardata["name"], thumb, pic, chardata["description"], chardata["urls"][0]["url"]));
                }
              }
            }
          }
        }
        window.localStorage["characters"] = JSON.encode(characters.toJson());
        if (data["data"]["offset"] + 100 < data["data"]["total"]) {
          fetchChars(offset: offset + 100).then((v) => completer.complete(v));
        } else {
          completer.complete(true);
        }
      }
    })
    .catchError((error) {
      completer.complete(false);
    });

  return completer.future;
}

void analyze(token) {
  Element progress = querySelector("#progress");
  if (token != null) {
    querySelector("#signin").style.display = "none";
    progress.innerHtml = "Logged in. Fetching activities...<br><br><br>";
    plus.makeAuthRequests = true;
    plus.activities.list("me", "public", maxResults: 100).then((pluslib_client.ActivityFeed data) {
      var text = "";
      for (var i = 0; i < data.items.length; i++) {
        pluslib_client.Activity item = data.items[i];
        var div = new DivElement();
        div.innerHtml = item.object.content;
        text = text + div.text;

        if (item.annotation != null && item.annotation != "") {
          div.innerHtml = item.annotation;
          text = text + " " + div.text;
        }
      }

      progress.innerHtml = "Finding matching characters...<br><br><br>";

      List wordlist = create_wordlist(text);
      characters.match(wordlist);

      templateBind(querySelector("#character"))
        ..bindingDelegate = new PolymerExpressions()
        ..model = characters.characters[0];

      progress.innerHtml = "";
    });
  }
}

void initialize(bool success) {
  auth = new oauth.GoogleOAuth2(CLIENT_ID, SCOPES, tokenLoaded: analyze);
  plus = new pluslib.Plus(auth);
  querySelector("#signin").style.display = "block";
  querySelector("#signinbtn").onClick.listen((_) => auth.login());
}

void main() {
  new Logger('polymer_expressions').onRecord.listen((LogRecord r) {
    print("${r.loggerName} ${r.level} ${r.message}");
  });

  templateBind(querySelector("#characters"))
    ..bindingDelegate = new PolymerExpressions()
    ..model = characters;

  if (window.localStorage.containsKey("characters")) {
    List chars = JSON.decode(window.localStorage["characters"]);
    for (var chardata in chars) {
      characters.add(new Character(chardata["name"], chardata["thumb"], chardata["pic"], chardata["description"], chardata["url"]));
    }
    initialize(true);
  } else {
    fetchChars().then(initialize);
  }
}