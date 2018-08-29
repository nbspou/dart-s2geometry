# S2 Geometry for Dart

[![Build Status](https://travis-ci.org/nbspou/dart-s2geometry.svg?branch=develop)](https://travis-ci.org/nbspou/dart-s2geometry)

Dart port of the C++ s2geometry and Go geo libraries.

## Usage

A simple usage example:

```
import 'package:s2geometry/s2geometry.dart';

main() {
  S2LatLng latLng = new S2LatLng.fromDegrees(49.703498679, 11.770681595);
  S2CellId cellId = new S2CellId.fromLatLng(latLng);
  print(cellId.toToken());
}
```

## Notes

This library depends on `int` being a 64 bit signed integer, and thus may not work under JavaScript targets.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/nbspou/dart-s2geometry/issues
