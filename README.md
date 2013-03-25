[![](https://drone.io/github.com/daegalus/formler/status.png)](https://drone.io/github.com/daegalus/formler/latest)

# formler

Simple form data parser.

Features:

* Handles multipart/form-data content.
* Handles x-www-urlencoded form content.
* [Annotated source code](http://daegalus.github.com/annotated/formler/formler/formler.html)

## Getting Started

### Pubspec

pub.dartlang.org: (you can use 'any' instead of a version if you just want the latest always)
```yaml
dependencies:
  formler: 0.0.1
```

```dart
#import('package:formler/formler.dart');
```

Start parsing ...

```dart
// Encode a hex string to base32
Formler formler = new Formler(bytes, "--someBoundaryStuff");
Map form = formler.parse(); // -> {fieldName: .... }

// base32 decoding to original string.
Formler.parseUrlEncoded("username=someValue+other%26val&password=eqwdawd9"); // -> { "username": "someValue other&val", "password": "eqwdawd9" }
```

## API

### new Formler(List<int> bytes, String boundary)

Creates a new Formler instance with the byte contents of the request and the boundary from the contentType.

* `bytes` - (List<int>) A list of bytes respresnting the POST form data.

Returns the new instance of `Formler`.

### formler.parse()

Actually does the parsing of the data and creates the data map of the contents.

Returns `Map` representation of the parsed data.

### (static) Formler.parseUrlEncoded(String postBody)

Parses a UrlEncoded post body string.

* `postBody` - (String) A string of key/urlencoded value pairs.

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
v0.0.1
- Initial Release
