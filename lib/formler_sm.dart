part of formler;

class FormlerSM {
  static final Map S = {
    "START": 0,
    "START_BOUNDARY": 1,
    "HEADER_FIELD_START" : 2,
    "HEADER_FIELD" : 3,
    "HEADER_VALUE_START" : 4,
    "HEADER_VALUE" : 5,
    "HEADER_VALUE_ALMOST_DONE" : 6,
    "HEADERS_ALMOST_DONE" : 7,
    "PART_DATA_START" : 8,
    "PART_DATA" : 9,
    "PART_END" : 10,
    "END" : 11
  };
  static final Map C = {
    "LF" : 10,
    "CR" : 13,
    "SPACE" : 32,
    "HYPHEN" : 45,
    "COLON" : 58,
    "A" : 97,
    "Z" : 122
  };

  Map callbacks;
  Map markers = new Map();
  List<int> data;
  String boundary;
  int state;
  int index = 0;
  int prevIndex = 0;
  int flags = 0;
  List<int> lookbehind;
  Map<int, bool> boundaryChars;

  FormlerSM(List<int> data, String boundary, Map callbacks) {
    this.data = data;
    this.boundary = "\r\n--"+boundary;
    this.callbacks = callbacks;
    state = S['START'];

    lookbehind = new List(boundary.length+8);
    boundaryChars = new Map();
    for (var i = 0; i < boundary.length; i++) {
      boundaryChars[boundary.codeUnits[i]] = true;
    }
  }

  Future<int> parse() {
    Completer completer = new Completer();
    for(int i = 0; i < data.length; i++) {
      int bit = data[i]; print("${bit} - ${i} - "+explain()+" - ${index}");

      switch(state) {
        case S['START']:
          index = 0;
          state = S['START_BOUNDARY'];
          continue startBoundary;

          startBoundary:
        case S['START_BOUNDARY']:
          if (index == boundary.length - 2) {
            if (bit != C['CR']) {
              return i;
            }
            index++;
            break;
          } else if (index - 1 == boundary.length - 2) {
            if (bit != C['LF']) {
              return i;
            }
            index = 0;
            _callback('partBegin');
            state = S['HEADER_FIELD_START'];
            break;
          }
          if (bit != boundary.codeUnits[index+2]) {
            index = -2;
          }
          if (bit == boundary.codeUnits[index+2]) {
            index++;
          }
          break;
        case S['HEADER_FIELD_START']:
          state = S['HEADER_FIELD'];
          _mark('headerField', i);
          index = 0;
          continue headerField;

          headerField:
        case S['HEADER_FIELD']:
          if (bit == C['CR']) {
            _clear('headerField');
            state = S['HEADERS_ALMOST_DONE'];
            break;
          }

          index++;
          if (bit == C['HYPHEN']) {
            break;
          }

          if (bit == C['COLON']) {
            if (index == 1) {
              return i;
            }
            _dataCallback('headerField', i, true);
            state = S['HEADER_VALUE_START'];
            break;
          }

          var bitl = _lower(bit);
          if (bitl < C['A'] || bitl > C['Z']) {
            return i;
          }
          break;
        case S['HEADER_VALUE_START']:
          if (bit == C['SPACE']) {
            break;
          }

          _mark('headerValue', i);
          state = S['HEADER_VALUE'];
          continue headerValueLabel;

          headerValueLabel:
        case S['HEADER_VALUE']:
          if (bit == C['CR']) {
            _dataCallback('headerValue', i, true);
            _callback('headerEnd');
            state = S['HEADER_VALUE_ALMOST_DONE'];
          }
          break;
        case S['HEADER_VALUE_ALMOST_DONE']:
          if (bit != C['LF']) {
            return i;
          }
          state = S['HEADER_FIELD_START'];
          break;
        case S['HEADERS_ALMOST_DONE']:
          print("LF = ${bit}}");
          if (bit != C['LF']) {
            return i;
          }

          _callback('headersEnd');
          state = S['PART_DATA_START'];
          break;
        case S['PART_DATA_START']:
          state = S['PART_DATA'];
          _mark('partData', i);
          continue partDataLabel;

          partDataLabel:
        case S['PART_DATA']:
          prevIndex = index;

          if (index == 0) {
            i += boundary.length-1;
            while (i < data.length && !(boundaryChars.containsKey(data[i]))) {
              i += boundary.length;
            }
            i -= boundary.length-1;
            bit = data[i];
          }

          if (index < boundary.length) {
            if (boundary[index] == bit) {
              if (index == 0) {
                _dataCallback('partData', i, true);
              }
              index++;
            } else {
              index = 0;
            }
          } else if (index == boundary.length) {
            index++;
            if (bit == C['CR']) {
              flags |= 1;
            } else if (c == S['HYPHEN']) {
              flags |= 2;
            } else {
              index = 0;
            }
          } else if (index - 1 == boundary.length)  {
            if (flags & 1) {
              index = 0;
              if (bit == S['LF']) {
                flags &= ~1;
                _callback('partEnd');
                _callback('partBegin');
                state = S['HEADER_FIELD_START'];
                break;
              }
            } else if (flags & 2) {
              if (bit == S['HYPHEN']) {
                _callback('partEnd');
                _callback('end');
                state = S['END'];
              } else {
                index = 0;
              }
            } else {
              index = 0;
            }
          }

          if (index > 0) {
            lookbehind[index-1] = bit;
          } else if (prevIndex > 0) {
            _callback('partData', 0, prevIndex);
            prevIndex = 0;
            _mark('partData');
            i--;
          }
          break;
        case S['END']:
          break;
        default:
          return i;
      }
    }

    _dataCallback('headerField');
    _dataCallback('headerValue');
    _dataCallback('partData');

    return data.length;
  }

  void end() {
    if ((state == S['HEADER_FIELD_START'] && index == 0) ||
    (state == S['PART_DATA'] && index == boundary.length)) {
      _callback('partEnd');
      _callback('end');
    } else if (this.state != S['END']) {
      return new Error('Formler.end(): stream ended unexpectedly: ' + explain());
    }
  }
  void explain() {
    var stateVal = S.values.toList().indexOf(state);
    print(state);
    return 'state = ${S.keys.toList()[stateVal]}';
  }

  int _lower(int character) {
    return character | 0x20;
  }

  void _mark(String name, int i) {
    markers[name+'Mark'] = i;
  }

  void _clear(String name) {
    markers.remove(name+'Mark');
  }

  void _callback(String name, [int start = null, int end = null]) {
    if (start != null && start == end) {
      return;
    }

    var callbackSymbol = 'on'+name.substring(0, 1).toUpperCase()+name.substring(1);
    if (callbacks.containsKey(callbackSymbol)) {
      callbacks[callbackSymbol](data, start, end);
    }
  }

  void _dataCallback(String name, [int i = 0, bool clear = false]) {
    var markSymbol = name+'Mark';
    if (!(markers.containsKey(markSymbol))) {
      return;
    }

    if (!clear) {
      _callback(name, markers[markSymbol], data.length);
      markers[markSymbol] = 0;
    } else {
      _callback(name, markers[markSymbol], i);
      markers.remove(markSymbol);
    }
  }
}
