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

import 'dart:typed_data';
import 'dart:math';

import 's2coords.dart';
import 's2coords_impl.dart';
import 's2point.dart';
export 's2point.dart';
import 's2latlng.dart';
import 'util/bits/bits.dart';

const int _kFaceBits = 3;
const int _kNumFaces = 6;
const int _kMaxLevel = kMaxCellLevel; // Valid levels: 0..kMaxLevel
const int _kPosBits = 2 * _kMaxLevel + 1;
const int _kMaxSize = 1 << _kMaxLevel;

const int _kLookupBits = 4;
Uint16List _lookupPos = new Uint16List(1 << (2 * _kLookupBits + 2));
Uint16List _lookupIJ = new Uint16List(1 << (2 * _kLookupBits + 2));

void _initLookupCell(
    int level, int i, int j, int origOrientation, int pos, int orientation) {
  if (level == _kLookupBits) {
    int ij = (i << _kLookupBits) + j;
    _lookupPos[(ij << 2) + origOrientation] = (pos << 2) + orientation;
    _lookupIJ[(pos << 2) + origOrientation] = (ij << 2) + orientation;
  } else {
    level++;
    i <<= 1;
    j <<= 1;
    pos <<= 2;
    List<int> r = kPosToIJ[orientation];
    _initLookupCell(level, i + (r[0] >> 1), j + (r[0] & 1), origOrientation,
        pos, orientation ^ kPosToOrientation[0]);
    _initLookupCell(level, i + (r[1] >> 1), j + (r[1] & 1), origOrientation,
        pos + 1, orientation ^ kPosToOrientation[1]);
    _initLookupCell(level, i + (r[2] >> 1), j + (r[2] & 1), origOrientation,
        pos + 2, orientation ^ kPosToOrientation[2]);
    _initLookupCell(level, i + (r[3] >> 1), j + (r[3] & 1), origOrientation,
        pos + 3, orientation ^ kPosToOrientation[3]);
  }
}

bool _flag = false;
void _maybeInit() {
  if (!_flag) {
    _flag = true;
    _initLookupCell(0, 0, 0, 0, 0, 0);
    _initLookupCell(0, 0, 0, kSwapMask, 0, kSwapMask);
    _initLookupCell(0, 0, 0, kInvertMask, 0, kInvertMask);
    _initLookupCell(
        0, 0, 0, kSwapMask | kInvertMask, 0, kSwapMask | kInvertMask);
  }
}

int _lsbForLevel(int level) {
  return 1 << (2 * (_kMaxLevel - level));
}

// need s2sphere.RegionCoverer

class S2CellId {
  S2CellId(this._id);

  S2CellId.fromPoint(S2Point p) {
    // ok
    S2FaceUV faceUv = xyzToFaceUV(p);
    int i = stToIJ(uvToST(faceUv.uv.u));
    int j = stToIJ(uvToST(faceUv.uv.v));
    _id = new S2CellId.fromFaceIJ(faceUv.face, i, j).id;
  }

  S2CellId.fromFace(int face) : _id = (face << _kPosBits) + _lsbForLevel(0) {}

  S2CellId.fromLatLng(S2LatLng latLng)
      : _id = new S2CellId.fromPoint(latLng.toPoint())._id {}

  S2CellId.fromFaceIJ(int face, int i, int j) {
    // Initialization if not done yet
    _maybeInit();

    // Optimization notes:
    //  - Non-overlapping bit fields can be combined with either "+" or "|".
    //    Generally "+" seems to produce better code, but not always.

    // Note that this value gets shifted one bit to the left at the end
    // of the function.
    int n = face << (_kPosBits - 1);

    // Alternating faces have opposite Hilbert curve orientations; this
    // is necessary in order for all faces to have a right-handed
    // coordinate system.
    int bits = (face & kSwapMask);

    // Each iteration maps 4 bits of "i" and "j" into 8 bits of the Hilbert
    // curve position.  The lookup table transforms a 10-bit key of the form
    // "iiiijjjjoo" to a 10-bit value of the form "ppppppppoo", where the
    // letters [ijpo] denote bits of "i", "j", Hilbert curve position, and
    // Hilbert curve orientation respectively.
    for (int k = 7; k >= 0; --k) {
      int mask = (1 << _kLookupBits) - 1;
      bits += ((i >> (k * _kLookupBits)) & mask) << (_kLookupBits + 2);
      bits += ((j >> (k * _kLookupBits)) & mask) << 2;
      bits = _lookupPos[bits];
      n |= (bits >> 2) << ((k) * 2 * _kLookupBits);
      bits &= (kSwapMask | kInvertMask);
    }

    _id = n * 2 + 1;
  }

  // Print the num_digits low order hex digits.
  String hexFormatString(int val, int numDigits) {
    // StringBuffer result = new StringBuffer(); // (numDigits, ' ');
    List<int> result = new List<int>.filled(numDigits, ' '.codeUnitAt(0));
    for (; numDigits-- > 0; val >>= 4)
      result[numDigits] = "0123456789abcdef".codeUnitAt(val & 0xF);
    return new String.fromCharCodes(result);
  }

  String toToken() {
    // Simple implementation: print the id in hex without trailing zeros.
    // Using hex has the advantage that the tokens are case-insensitive, all
    // characters are alphanumeric, no characters require any special escaping
    // in queries for most indexing systems, and it's easy to compare cell
    // tokens against the feature ids of the corresponding features.
    //
    // Using base 64 would produce slightly shorter tokens, but for typical cell
    // sizes used during indexing (up to level 15 or so) the average savings
    // would be less than 2 bytes per cell which doesn't seem worth it.

    // "0" with trailing 0s stripped is the empty string, which is not a
    // reasonable token.  Encode as "X".
    if (_id == 0) return "X";
    int numZeroDigits = findLSBSetNonZero64(_id) ~/ 4;
    int shift = (4 * numZeroDigits);
    return hexFormatString(
        (_id >> shift) & ((1 << (64 - shift)) - 1), 16 - numZeroDigits);
  }

  // lsbForLevel returns the lowest-numbered bit that is on for cells at the given level.
  // func lsbForLevel(level int) uint64 { return 1 << uint64(2*(maxLevel-level)) }

  // Parent returns the cell at the given level, which must be no greater than the current level.
  S2CellId parent([int level]) {
    int lsb = _lsbForLevel(level == null ? this.level - 1 : level);
    return new S2CellId((_id & -lsb) | lsb);
  }

  // immediateParent is cheaper than Parent, but assumes !ci.isFace().
  S2CellId immediateParent() {
    int nlsb = lsb() << 2;
    return new S2CellId((_id & -nlsb) | nlsb);
  }

  // isFace returns whether this is a top-level (face) cell.
  bool isFace() {
    return _id & (_lsbForLevel(0) - 1) == 0;
  }

  // lsb returns the least significant bit that is set.
  int lsb() {
    return _id & -_id;
  }

  S2CellId.fromFaceIJWrap(int face, int i, int j) {
    // Convert i and j to the coordinates of a leaf cell just beyond the
    // boundary of this face.  This prevents 32-bit overflow in the case
    // of finding the neighbors of a face cell.
    i = max(-1, min(_kMaxSize, i));
    j = max(-1, min(_kMaxSize, j));

    // We want to wrap these coordinates onto the appropriate adjacent face.
    // The easiest way to do this is to convert the (i,j) coordinates to (x,y,z)
    // (which yields a point outside the normal face boundary), and then call
    // S2::XYZtoFaceUV() to project back onto the correct face.
    //
    // The code below converts (i,j) to (si,ti), and then (si,ti) to (u,v) using
    // the linear projection (u=2*s-1 and v=2*t-1).  (The code further below
    // converts back using the inverse projection, s=0.5*(u+1) and t=0.5*(v+1).
    // Any projection would work here, so we use the simplest.)  We also clamp
    // the (u,v) coordinates so that the point is barely outside the
    // [-1,1]x[-1,1] face rectangle, since otherwise the reprojection step
    // (which divides by the new z coordinate) might change the other
    // coordinates enough so that we end up in the wrong leaf cell.
    double kScale = 1.0 / _kMaxSize;
    Uint8List buffer = new Uint8List(8);
    buffer.buffer.asFloat64List()[0] = 1.0;
    ++buffer.buffer.asUint64List()[0];
    double kLimit = buffer.buffer.asFloat64List()[0];
    // The arithmetic below is designed to avoid 32-bit integer overflows.
    assert(0 == _kMaxSize % 2);
    double u =
        max(-kLimit, min(kLimit, kScale * (2 * (i - _kMaxSize / 2) + 1)));
    double v =
        max(-kLimit, min(kLimit, kScale * (2 * (j - _kMaxSize / 2) + 1)));

    // Find the leaf cell coordinates on the adjacent face, and convert
    // them to a cell id at the appropriate level.
    S2FaceUV faceUV = xyzToFaceUV(faceUVToXYZ(face, new R2Point(u, v)));
    _id = new S2CellId.fromFaceIJ(faceUV.face, stToIJ(0.5 * (faceUV.u + 1)),
            stToIJ(0.5 * (faceUV.v + 1)))
        ._id;
  }

  S2CellId.fromFaceIJSame(int face, int i, int j, bool same_face) {
    if (same_face)
      _id = new S2CellId.fromFaceIJ(face, i, j)._id;
    else
      _id = new S2CellId.fromFaceIJWrap(face, i, j)._id;
  }

/*
  List<S2CellId> GetEdgeNeighbors() {
    int i, j;
    int level = this.level;
    int size = getSizeIJ(level);
    int face = toFaceIJOrientation(i, j, nullptr);

    List<S2CellId> neighbors = new List<S2CellId>(4);
    // Edges 0, 1, 2, 3 are in the down, right, up, left directions.
    neighbors[0] =
        new S2CellId.fromFaceIJSame(face, i, j - size, j - size >= 0).parent(level);
    neighbors[1] =
        new S2CellId.fromFaceIJSame(face, i + size, j, i + size < _kMaxSize).parent(level);
    neighbors[2] =
        new S2CellId.fromFaceIJSame(face, i, j + size, j + size < _kMaxSize).parent(level);
    neighbors[3] =
        new S2CellId.fromFaceIJSame(face, i - size, j, i - size >= 0).parent(level);
    return neighbors;
  }*/

  int get level {
    return _kMaxLevel - (findLSBSetNonZero64(_id) >> 1);
  }

  int get id {
    return _id;
  }

  int _id = 0;

  @override
  int get hashCode {
    return _id;
  }

  @override
  bool operator ==(Object other) {
    S2CellId cellId = other;
    return _id == cellId._id;
  }

  bool operator <(Object other) {
    // Unsigned comparison
    S2CellId cellId = other;
    if (_id > 0 == cellId._id > 0) {
      return _id < cellId._id;
    }
    return _id > 0;
  }

  bool operator >(Object other) {
    // Unsigned comparison
    S2CellId cellId = other;
    if (_id > 0 == cellId._id > 0) {
      return _id > cellId._id;
    }
    return _id < 0;
  }
}
