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

class R2Point {
  R2Point(this.x, this.y);
  R2Point.zero() : x = 0.0, y = 0.0;
  double x, y;
  double operator [](int index) {
    switch (index) {
      case 0:
        return x;
      case 1:
        return y;
      default:
        throw new Exception("Invalid index");
    }
  }

  double get u {
    return x;
  }

  double get v {
    return y;
  }
}
