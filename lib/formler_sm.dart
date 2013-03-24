part of formler;

class FormlerSM {
  static const Map S = {
    "START": 1,
    "START_BOUNDARY": 2,
    "HEADER_FIELD_START" : 3,
    "HEADER_FIELD" : 4,
    "HEADER_VALUE_START" : 5,
    "HEADER_VALUE" : 6,
    "HEADER_VALUE_ALMOST_DONE" : 7,
    "HEADERS_ALMOST_DONE" : 8,
    "PART_DATA_START" : 9,
    "PART_DATA" : 10,
    "PART_END" : 11,
    "END" : 12
  };
  static const Map C = {
    "LF" : 10,
    "CR" : 13,
    "SPACE" : 32,
    "HYPHEN" : 45,
    "COLON" : 58,
    "A" : 97,
    "Z" : 122
  };

  Map parseData = new Map();
  List<int> data;
  String boundary;
  int state;
  int index = 0;
  int prevIndex = 0;
  int flags = 0;
  List<int> lookbehind;
  Map<int, bool> boundaryChars;

  FormlerSM(List<int> data, String boundary) {
    this.data = data;
    this.boundary = "\r\n--"+boundary;
    state = S['START'];

    lookbehind = new List(boundary.length+8);
    boundaryChars = new Map();
    for (var i = 0; i < boundary.length; i++) {
      boundaryChars[boundary.codeUnits[i]] = true;
    }
  }

  int parse() {
    for(int i = 0; i < data.length; i++) {
      int bit = data[i];

      switch(state) {
        case S['START']:
          index = 0;
          state = _START_BOUNDARY;
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

          if (bit != boundary[index+2]) {
            index = -2;
          }
          if (bit == boundary[index+2]) {
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
            clear('headerField');
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

          _mark('headerValue');
          state = S['HEADER_VALUE'];
          continue headerValue;

          headerValue:
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
          state = C['HEADER_FIELD_START'];
          break;
        case S['HEADERS_ALMOST_DONE']:
          if (bit != C['LF']) {
            return i;
          }

          _callback('headersEnd');
          state = S['PART_DATA_START'];
          break;
        case S['PART_DATA_START']:
          state = S['PART_DATA'];
          _mark('partData');
          continue partData;

          partData:
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
            _callback('partData', lookbehind, 0, prevIndex);
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

    return len;
  }

  void end() {
    if ((state == S['HEADER_FIELD_START'] && index == 0) ||
    (state == S['PART_DATA'] && index == boundary.length)) {
      _callback(this, 'partEnd');
      _callback(this, 'end');
    } else if (this.state != S['END']) {
      return new Error('Formler.end(): stream ended unexpectedly: ' + explain());
    }
  }
  void explain() {
    var stateNum = 0;
    for(int j = 0; j <= S.values; j++) {
      if(S.values[j] == state) {
        stateNum = j;
        break;
      }
    }
    return 'state = ${S.keys[j]}';
  }

  int _lower(int character) {
    return character | 0x20;
  }

  void _mark(String name, int i) {
    parseData[name+'Mark'] = i;
  }

  void _clear(String name) {
    parseData.remove(name+'Mark');
  }

  void _callback(String name, [start = 0, end = -1]) {
    if (start != null && start == end) {
      return;
    }

    var callbackSymbol = 'on'+name.substring(0, 1).toUpperCase()+name.substring(1);
    if (parseData.containsKey(callbackSymbol)) {
      parseData[callbackSymbol](start, end);
    }
  }

  void _dataCallback(String name, int i, bool clear) {
    var markSymbol = name+'Mark';
    if (!(parseData.containsKey(markSymbol))) {
      return;
    }

    if (!clear) {
      callback(name, parseData[markSymbol], data.length);
      parseData[markSymbol] = 0;
    } else {
      callback(name, parseData[markSymbol], i);
      parseData.remove(markSymbol);
    }
  }
}
