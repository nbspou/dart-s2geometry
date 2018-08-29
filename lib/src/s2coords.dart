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
import 'r2point.dart';
import 's2point.dart';
import 's2coords_impl.dart';

// This is the number of levels needed to specify a leaf cell.  This
// constant is defined here so that the S2::Metric class and the conversion
// functions below can be implemented without including s2cell_id.h.  Please
// see s2cell_id.h for other useful constants and conversion functions.

const int kMaxCellLevel = 30;

// The maximum index of a valid leaf cell plus one.  The range of valid leaf
// cell indices is [0..kLimitIJ-1].
const int kLimitIJ = 1 << kMaxCellLevel; // == S2CellId::kMaxSize

// The maximum value of an si- or ti-coordinate.  The range of valid (si,ti)
// values is [0..kMaxSiTi].
const int kMaxSiTi = 1 << (kMaxCellLevel + 1);

double stToUV(double s) {
  if (s >= 0.5)
    return (1.0 / 3.0) * (4 * s * s - 1);
  else
    return (1.0 / 3.0) * (1 - 4 * (1 - s) * (1 - s));
}

double uvToST(double u) {
  if (u >= 0)
    return 0.5 * sqrt(1 + 3 * u);
  else
    return 1 - 0.5 * sqrt(1 - 3 * u);
}

double ijToSTMin(int i) {
  assert(i >= 0 && i <= kLimitIJ);
  return (1.0 / kLimitIJ) * i;
}

int stToIJ(double s) {
  return max(0, min(kLimitIJ - 1, (kLimitIJ * s - 0.5).round()));
}

double siTiToST(int si) {
  assert(si <= kMaxSiTi);
  return (1.0 / kMaxSiTi) * si;
}

int stToSiTi(double s) {
  // kMaxSiTi == 2^31, so the result doesn't fit in an int32 when s == 1.
  return (s * kMaxSiTi).round();
}

S2Point faceUVToXYZ(int face, R2Point uv) {
  switch (face) {
    case 0:
      return S2Point(1.0, uv.u, uv.v);
    case 1:
      return S2Point(-uv.u, 1.0, uv.v);
    case 2:
      return S2Point(-uv.u, -uv.v, 1.0);
    case 3:
      return S2Point(-1.0, -uv.v, -uv.u);
    case 4:
      return S2Point(uv.v, -1.0, -uv.u);
    default:
      return S2Point(uv.v, uv.u, -1.0);
  }
}

R2Point validFaceXYZToUV(int face, S2Point p) {
  // assert(p.DotProd(GetNorm(face)) > 0);
  R2Point res = new R2Point(0.0, 0.0);
  switch (face) {
    case 0:
      res.x = p[1] / p[0];
      res.y = p[2] / p[0];
      break;
    case 1:
      res.x = -p[0] / p[1];
      res.y = p[2] / p[1];
      break;
    case 2:
      res.x = -p[0] / p[2];
      res.y = -p[1] / p[2];
      break;
    case 3:
      res.x = p[2] / p[0];
      res.y = p[1] / p[0];
      break;
    case 4:
      res.x = p[2] / p[1];
      res.y = -p[0] / p[1];
      break;
    default:
      res.x = -p[1] / p[2];
      res.y = -p[0] / p[2];
      break;
  }
  return res;
}

int getFace(S2Point p) {
  int face = p.largestAbsComponent();
  if (p[face] < 0) face += 3;
  return face;
}

class S2FaceUV {
  int face;
  R2Point uv;
  double get u { return uv.u; }
  double get v { return uv.v; }
}

S2FaceUV xyzToFaceUV(S2Point p) {
  S2FaceUV res = new S2FaceUV();
  res.face = getFace(p);
  res.uv = validFaceXYZToUV(res.face, p);
  return res;
}

R2Point faceXYZtoUV(int face, S2Point p) {
  if (face < 3) {
    if (p[face] <= 0) return null;
  } else {
    if (p[face - 3] >= 0) return null;
  }
  return validFaceXYZToUV(face, p);
}

S2Point getUNorm(int face, double u) {
  switch (face) {
    case 0:
      return S2Point(u, -1.0, 0.0);
    case 1:
      return S2Point(1.0, u, 0.0);
    case 2:
      return S2Point(1.0, 0.0, u);
    case 3:
      return S2Point(-u, 0.0, 1.0);
    case 4:
      return S2Point(0.0, -u, 1.0);
    default:
      return S2Point(0.0, -1.0, -u);
  }
}

S2Point getVNorm(int face, double v) {
  switch (face) {
    case 0:
      return S2Point(-v, 0.0, 1.0);
    case 1:
      return S2Point(0.0, -v, 1.0);
    case 2:
      return S2Point(0.0, -1.0, -v);
    case 3:
      return S2Point(v, -1.0, 0.0);
    case 4:
      return S2Point(1.0, v, 0.0);
    default:
      return S2Point(1.0, 0.0, v);
  }
}

S2Point getNorm(int face) {
  return getUVWAxis(face, 2);
}

S2Point getUAxis(int face) {
  return getUVWAxis(face, 0);
}

S2Point getVAxis(int face) {
  return getUVWAxis(face, 1);
}

S2Point getUVWAxis(int face, int axis) {
  List<double> p = kFaceUVWAxes[face][axis];
  return S2Point(p[0], p[1], p[2]);
}

int getUVWFace(int face, int axis, int direction) {
  assert(face >= 0 && face <= 5);
  assert(axis >= 0 && axis <= 2);
  assert(direction >= 0 && direction <= 1);
  return kFaceUVWFaces[face][axis][direction];
}
