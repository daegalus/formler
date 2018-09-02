[![Build Status](https://travis-ci.org/Daegalus/formler.svg?branch=master)](https://travis-ci.org/Daegalus/formler)

# formler

[![Join the chat at https://gitter.im/Daegalus/formler](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Daegalus/formler?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Simple form data parser.

Features:

- Handles multipart/form-data content.
- Handles x-www-urlencoded form content.
- [Annotated source code](http://daegalus.github.com/annotated/formler/formler/formler.html)

## Getting Started

### Pubspec

pub.dartlang.org: (you can use 'any' instead of a version if you just want the latest always)

```yaml
dependencies:
  formler: 1.0.0
```

```dart
import 'package:formler/formler.dart';
```

Start parsing ...

```dart
// Parse a Multipart form
Formler formler = new Formler(bytes, "--someBoundaryStuff");
Map form = formler.parse(); // -> {fieldName: .... }

// Parse a UrlEncoded form
Formler.parseUrlEncoded("username=someValue+other%26val&password=eqwdawd9"); // -> { "username": "someValue other&val", "password": "eqwdawd9" }
```

## API

### new Formler(List<int> bytes, String boundary)

Creates a new Formler instance with the byte contents of the request and the boundary from the contentType.

- `bytes` - (List<int>) A list of bytes respresnting the POST form data.

Returns the new instance of `Formler`.

### formler.parse()

Actually does the parsing of the data and creates the data map of the contents.

Returns `Map` representation of the parsed data.

### (static) Formler.parseUrlEncoded(String postBody, [bool printErrors = true])

Parses a UrlEncoded post body string.

- `postBody` - (String) A string of key/urlencoded value pairs.
- `printErrors` - (Bool) Set to false if you don't want Formler to print warnings to STDOUT. Default is true.

Returns `Map` representation of the parsed Data

Example: Encode a hex string.

## Testing

In dartvm

```
dart test\formler_test.dart
```

In Browser

At the moment, this package does not work client-side as it uses server-side only UInt8Lists. I might have to wait till UInt8Arrays and UInt8Lists are merged into 1

## Release notes

v0.1.2

- Pull Request accepted to fix package versions for increased compatibility.

v0.1.1

- Fix empty string and handle malformed urlencoded strings gracefully.

v0.1.0

- Dart 1.0 Readiness

v0.0.8

- Fixing analyzer complaints.

v0.0.7

- Fixing package changes for Crypto and URI

v0.0.6

- Including fixes for TypedData and Regex and also switched to useing the Base64 Decode built into Crypto now.

v0.0.5

- Accepted pull request to add multi-file support. Must have overlooked this in my excitement to get this parser working.

v0.0.4

- Fixing an import/part issue that affected Fukiya.

v0.0.3

- Binary file upload parsing bug fixed.

v0.0.2

- Parsing Bugs.

v0.0.1

- Initial Release
