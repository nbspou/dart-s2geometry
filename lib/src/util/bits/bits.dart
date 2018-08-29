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

int log2Floor(int n) {
  if (n == 0) return -1;
  int log = 0;
  int value = n;
  for (int i = 4; i >= 0; --i) {
    int shift = (1 << i);
    int x = value >> shift;
    if (x != 0) {
      value = x;
      log += shift;
    }
  }
  assert(value == 1);
  return log;
}

int log2FloorNonZero64(int n) {
  int topbits = (n >> 32) & 0xFFFFFFFF;
  if (topbits == 0) {
    // Top bits are zero, so scan in bottom bits
    return log2Floor(n & 0xFFFFFFFF);
  } else {
    return 32 + log2Floor(topbits);
  }
}

int findMSBSetNonZero64(int n) {
  return log2FloorNonZero64(n);
}

int findLSBSetNonZero(int n) {
  int rc = 31;
  for (int i = 4, shift = 1 << 4; i >= 0; --i) {
    int x = (n << shift) & 0xFFFFFFFF;
    if (x != 0) {
      n = x;
      rc -= shift;
    }
    shift >>= 1;
  }
  return rc;
}

int findLSBSetNonZero64(int n) {
  int bottombits = n & 0xFFFFFFFF;
  if (bottombits == 0) {
    // Bottom bits are zero, so scan in top bits
    return 32 + findLSBSetNonZero((n >> 32) & 0xFFFFFFFF);
  } else {
    return findLSBSetNonZero(bottombits);
  }
}