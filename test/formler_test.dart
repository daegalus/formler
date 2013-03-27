import 'package:formler/formler.dart';
import 'package:unittest/unittest.dart';
import 'dart:io';

main() {
  simpleTest();
  complexTest();
}

void simpleTest() {
  test("Simple Parsing Test", () {
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

    Formler formler = new Formler(postData.codeUnits, "aab03x");
    Map data = formler.parse();

    expect(data['submit-name']['data'], equals("Larry"));
    expect(data['file']['filename'], equals("image.jpg"));
    expect(data['file']['mime'], equals("image/jpeg"));
    expect(data['file']['transferEncoding'], equals("base64"));
  });

}

void complexTest() {
  test("Complex Parsing Test with Binary File", () {
    String postData =  '--AaB03x\r\n'
    'Content-Disposition: form-data; name="submit-name"\r\n'
    '\r\n'
    'Larry\r\n'
    '--AaB03x\r\n'
    'Content-Disposition: form-data; name="file"; filename="image.jpg"\r\n'
    'Content-Type: image/jpeg\r\n'
    'Content-Transfer-Encoding: binary\r\n'
    '\r\n';
    String endPostData = '\r\n--AaB03x--';

    File file = new File('./test/image.jpg');
    List<int> fileData = file.readAsBytesSync();

    List<int> sendData = new List<int>();
    sendData..addAll(postData.codeUnits)..addAll(fileData)..addAll(endPostData.codeUnits);

    Formler formler = new Formler(sendData, "aab03x");
    Map data = formler.parse();

    expect(data['submit-name']['data'], equals("Larry"));
    expect(data['file']['filename'], equals("image.jpg"));
    expect(data['file']['mime'], equals("image/jpeg"));
    expect(data['file']['transferEncoding'], equals("binary"));
  });
}