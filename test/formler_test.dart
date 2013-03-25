import 'package:formler/formler.dart';
import 'package:unittest/unittest.dart';
main() {
  String postData =  '--AaB03x\r\n'
  'Content-Disposition: form-data; name="submit-name"\r\n'
  '\r\n'
  'Larry\r\n'
  '--AaB03x\r\n'
  'Content-Disposition: form-data; name="file"; filename="image.jpg"\r\n'
  'Content-Type: image/jpeg\r\n'
  'Content-Transfer-Encoding: base64\r\n'
  '\r\n'
  'YQ=='
  '\r\n--AaB03x--';

  Formler formler = new Formler(postData.codeUnits, "AaB03x");
  Map data = formler.parse();
  print(data);
}