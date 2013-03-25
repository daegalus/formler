library formler;
import 'dart:collection';
import 'dart:io';
import 'dart:async';
part 'formler_sm.dart';
part 'helper/base64_decoder.dart';

main() {
  Formler formler = new Formler('------TLV0SrKD4z1TRxRhAPUvZ\r\n'
                                'Content-Disposition: form-data; name="file"; filename="plain.txt"\r\n'
                                'Content-Type: text/plain\r\n'
                                'Content-Transfer-Encoding: 7bit\r\n'
                                '\r\n'
                                'I am a plain text file\r\n'
                                '\r\n'
                                '------TLV0SrKD4z1TRxRhAPUvZ--'.codeUnits,'----TLV0SrKD4z1TRxRhAPUvZ');
  Map form = formler.readForm();
  print(form);
}


class Formler {

  FormlerSM stateMachine;
  Base64Decoder base64Decoder;
  Map<String, Function> callbacks;
  Map files;
  Map file = new Map();
  String headerField = '';
  String headerValue = '';

  Formler(List<int> data, String boundary) {
    callbacks = new Map<String, Function>();
    files = new Map();
    stateMachine = new FormlerSM(data, boundary, callbacks);
    base64Decoder = new Base64Decoder();

    callbacks['onPartBegin'] = (List<int> b, int start, int end) {
      file['headers'] = {};
      file['name'] = null;
      file['filename'] = null;
      file['mime'] = null;

      file['transferEncoding'] = 'binary';
      file['transferBuffer'] = '';

      headerField = '';
      headerValue = '';
    };

    callbacks['onHeaderField'] = (List<int> b, int start, int end) {
      headerField += new String.fromCharCodes(b.sublist(start,end));
    };

    callbacks['onHeaderValue'] = (List<int> b, int start, int end) {
      headerValue += new String.fromCharCodes(b.sublist(start,end));
    };

    callbacks['onHeaderEnd'] = (List<int> b, int start, int end) {
      headerField = headerField.toLowerCase();
      file['headers'][headerField] = headerValue;

      var nameRegex = new RegExp(r'/\bname="([^"]+)"/i');
      if (headerField == 'content-disposition') {
        if (nameRegex.hasMatch(headerValue)) {
          file['name'] = nameRegex.firstMatch(headerValue).group(1);
        }
        file['filename'] = _fileName(headerValue);
      } else if (headerField == 'content-type') {
        file['mime'] = headerValue;
      } else if (headerField == 'content-transfer-encoding') {
        file['transferEncoding'] = headerValue.toLowerCase();
      }

      headerField = '';
      headerValue = '';
    };

    callbacks['onHeadersEnd'] = (List<int> b, int start, int end) {
      switch(file['transferEncoding']){
        case 'binary':
        case '7bit':
        case '8bit':
          callbacks['onPartData'] = (List<int> b, int start, int end) {
            if(file['data'] == null)
              file['data'] = new List<int>();
            file['data'].addAll(b.sublist(start, end));
          };

          callbacks['onPartEnd'] = () {
            files[file['name']] = file;
          };
          break;

        case 'base64':
          callbacks['onPartData'] = (List<int> b, int start, int end) {
            if(file['data'] == null)
              file['data'] = '';
            file['data'] += new String.fromCharCodes(b.sublist(start, end));
          };

          callbacks['onPartEnd'] = (List<int> b, int start, int end) {
            file['data'] = base64Decoder.decode(file['data']);
            files[file['name']] = file;
          };
          break;

        default:
          throw new Exception('unknown transfer-encoding');
      }
    };

    callbacks['onEnd'] = (List<int> b, int start, int end) {
      stateMachine.end();
    };
  }

  void readForm() {
    stateMachine.parse();
    return files;
  }

  String _fileName(headerValue) {
    var filenameRegex = new RegExp(r'/\bfilename="(.*?)"($|; )/i');
    if (!filenameRegex.hasMatch(headerValue))
      return '';

    var fileMatch = filenameRegex.firstMatch(headerValue);

    var filename = fileMatch.group(1).substring(fileMatch.group(1).lastIndexOf('\\') + 1);
    filename = filename.replaceAll(r'/%22/g', '"');
    filename = filename.replaceAllMapped(r'/&#([\d]{4});/g', (Match match) {
      return new String.fromCharCodes(match.group(1).codeUnits);
    });
    return filename;
  }

}
