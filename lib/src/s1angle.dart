// Copyright 2005 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS-IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// Ported from the C++ s2geometry and Go geo libraries to Dart by
// Jan Boon <kaetemi@no-break.space>

import 'dart:math';

class S1Angle {
  double _radians;
  S1Angle() : _radians = 0.0 {}

  S1Angle.fromRadians(double radians) : _radians = radians {}

  S1Angle.fromDegrees(double degrees) : _radians = (pi / 180.0) * degrees {}

  double get radians {
    return _radians;
  }

  double get degrees {
    return (180.0 / pi) * _radians;
  }

  static S1Angle get infinity {
    return S1Angle.fromRadians(double.infinity);
  }

  static S1Angle get zero {
    return S1Angle.fromRadians(0.0);
  }

  @override
  int get hashCode {
    return _radians.hashCode;
  }

  @override
  bool operator ==(Object other) {
    S1Angle angle = other;
    return _radians == angle._radians;
  }

  bool operator <(Object other) {
    S1Angle angle = other;
    return _radians < angle._radians;
  }

  bool operator >(Object other) {
    S1Angle angle = other;
    return _radians > angle._radians;
  }
}
