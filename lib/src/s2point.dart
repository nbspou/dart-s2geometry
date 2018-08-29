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

class S2Point {
  S2Point(this.x, this.y, this.z);
  double x, y, z;
  double operator [](int index) {
    switch (index) {
      case 0:
        return x;
      case 1:
        return y;
      case 2:
        return z;
      default:
        throw new Exception("Invalid index");
    }
  }

  S2Point abs() {
    return new S2Point(x.abs(), y.abs(), z.abs());
  }

  int largestAbsComponent() {
    S2Point temp = abs();
    return temp[0] > temp[1]
        ? temp[0] > temp[2] ? 0 : 2
        : temp[1] > temp[2] ? 1 : 2;
  }
}
