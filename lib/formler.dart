library formler;
import 'dart:collection';
import 'dart:io';
import 'dart:async';
import 'dart:uri';
import 'dart:typeddata';
import 'helper/base64_decoder.dart';

class Formler {

  final RegExp dispRegex = new RegExp(r'Content-Disposition: ([\S]+); name="([\S]+)"');
  final RegExp dispFileRegex = new RegExp(r'Content-Disposition: ([\S]+); name="([\S]+)"; filename="([\w\.]+)"');
  final RegExp typeRegex = new RegExp(r'Content-Type: ([\S]+)');
  final RegExp transferRegex = new RegExp(r'Content-Transfer-Encoding: ([\S]+)');

  static final Map C = {
      "LF" : 10,
      "CR" : 13,
      "SPACE" : 32,
      "HYPHEN" : 45,
      "COLON" : 58,
      "A" : 97,
      "Z" : 122
  };

  const BOUNDARY = 0;
  const HEADERS = 1;
  const PART_DATA = 2;
  const END = 3;

  Base64Decoder base64Decoder;
  Map formData;
  List<int> data;
  String boundary;
  List<int> dataGather;
  int state;
  String currentName;
  Map currentFile;

  Formler(List<int> data, String boundary) {
    this.data = data;
    this.boundary = boundary;

    base64Decoder = new Base64Decoder();
    formData = {};
    dataGather = [];
    state = BOUNDARY;
    currentName = '';
    currentFile = {};
  }

  static Map parseUrlEncoded(String content) {
    List<String> segments = content.split("&");
    Map parsed = {};

    for(String segment in segments) {
      List<String> pair = segment.split('=');
      parsed[pair[0]] = (pair.toList().length == 2) ? _urlDecode(pair[1]) : '';
    }
    return parsed;
  }

  static String _urlDecode(String encoded) => decodeUriComponent(encoded.replaceAll("+", " "));

  Map parse() {
    List<int> currentLine = [];
    for(int i = 0; i < data.length; i++) {
      var bit = data[i];

      var lookahead = (i+1 == data.length) ? data[i] : data[i+1];

      if(state == PART_DATA){
        var lookaheadm = data[i+2];
        if(bit == C['CR'] && lookahead == C['LF'] && lookaheadm == C['HYPHEN']) {
          _stateLine(currentLine);
          i++;
          currentLine = [];
          state = HEADERS;
        } else {
          currentLine.add(bit);
        }
      } else {
        if(bit == C['CR'] && lookahead == C['LF']) {
          _stateLine(currentLine);
          i++;
          currentLine = [];
        } else {
          currentLine.add(bit);
        }
      }
      if(i == data.length - 1) {
        _stateLine(currentLine);
      }
    }
    return formData;
  }

  void _stateLine(List<int> line) {
    String lineString = new String.fromCharCodes(line);
    switch(state) {
      case BOUNDARY:
        if(lineString.toLowerCase().contains("--${boundary}")) {
          state = HEADERS;
          break;
        }
        //_dataGatherProcess();
        currentName = '';
        state = HEADERS;
        break;
      case HEADERS:
        if(lineString.toLowerCase().contains("--${boundary}")) {
          _dataGatherProcess();
          state = HEADERS;
          break;
        }
        if(dispFileRegex.hasMatch(lineString)) {
          var match = dispFileRegex.firstMatch(lineString);
          var name = match.group(2);
          var filename = match.group(3);
          currentName = match.group(2);
          currentFile = {};
          currentFile['filename'] = filename;
          break;
        } else if(dispRegex.hasMatch(lineString)) {
          var match = dispRegex.firstMatch(lineString);
          var name = match.group(2);
          currentName = match.group(2);
          currentFile = {};
          break;
        } else if(typeRegex.hasMatch(lineString)) {
          var match = typeRegex.firstMatch(lineString);
          var type = match.group(1);
          currentFile['mime'] = type;
          break;
        } else if(transferRegex.hasMatch(lineString)) {
          var match = transferRegex.firstMatch(lineString);
          var transfer = match.group(1);
          currentFile['transferEncoding'] = transfer;
          break;
        } else if(lineString == "") {
          state = PART_DATA;
          break;
        } else {
          state = PART_DATA;
          break;
        }
        break;
      case PART_DATA:
        if(lineString.toLowerCase().contains("--${boundary}--")) {
          _dataGatherProcess();
          state = END;
          break;
        }
        if(lineString.toLowerCase().contains("--${boundary}")) {
          _dataGatherProcess();
          state = HEADERS;
          break;
        }


        dataGather.addAll(line);
        break;
      case END:
        break;
    };
  }

  void _dataGatherProcess() {
    if(dataGather.length > 0) {
      if(currentFile['transferEncoding'] == "base64") {
        if(currentFile['data'] == null) { currentFile['data'] = []; }
        currentFile['data'].addAll(base64Decoder.decode(new String.fromCharCodes(dataGather)));
      }
      else if(currentFile['transferEncoding'] == "quoted-printable") {
        if(currentFile['data'] == null) { currentFile['data'] = ''; }
        currentFile['data'] += new String.fromCharCodes(dataGather);
      }
      else if((currentFile['transferEncoding'] == null && currentFile['mime'] == "text/plain") ||
              (currentFile['filename'] == null && currentFile['transferEncoding'] == null)){
        if(currentFile['data'] == null) { currentFile['data'] = ''; }
        currentFile['data'] += new String.fromCharCodes(dataGather);
      }
      else {
        if(currentFile['data'] == null) { currentFile['data'] = []; }
        currentFile['data'].addAll(dataGather);
      }
      dataGather.clear();
    }

    if (formData[currentName] == null) {
      formData[currentName] = currentFile;
    } else if (formData[currentName] is List) {
      formData[currentName].add(currentFile);
    } else {
      // Is the second file. Create a list to store the results.
      List<Map> files = new List<Map>();
      files.add(formData[currentName]);
      files.add(currentFile);
      formData[currentName] = files;
    }
  }
}
