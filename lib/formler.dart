library formler;
import 'dart:collection';
import 'dart:io';
part 'formler_sm.dart';

main() {
  Formler formler = new Formler([],"");
  formler.parse();
}


class Formler {

  FormlerSM stateMachine;

  Map readForm(HttpRequest request) {

  }

}
