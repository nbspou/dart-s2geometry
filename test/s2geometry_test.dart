import 'package:s2geometry/s2geometry.dart';
import 'package:test/test.dart';

void main() {
  group('S2CellId', () {
    test('S2CellId.fromLatLng', () {
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(49.703498679, 11.770681595))
              .id,
          0x47a1cbd595522b39);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(55.685376759, 12.588490937))
              .id,
          0x46525318b63be0f9);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(45.486546517, -93.449700022))
              .id,
          0x52b30b71698e729d);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(58.299984854, 23.049300056))
              .id,
          0x46ed8886cfadda85);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(34.364439040, 108.330699969))
              .id,
          0x3663f18a24cbe857);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(-30.694551352, -30.048758753))
              .id,
          0x10a06c0a948cf5d);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(-25.285264027, 133.823116966))
              .id,
          0x2b2bfd076787c5df);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(-75.000000031, 0.000000133))
              .id,
          0xb09dff882a7809e1);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(-24.694439215, -47.537363213))
              .id,
          0x94daa3d000000001);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(38.899730392, -99.901813021))
              .id,
          0x87a1000000000001);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(81.647200334, -55.631712940))
              .id,
          0x4fc76d5000000001);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(10.050986518, 78.293170610))
              .id,
          0x3b00955555555555);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(-34.055420593, 18.551140038))
              .id,
          0x1dcc469991555555);
      expect(
          new S2CellId.fromLatLng(
                  new S2LatLng.fromDegrees(-69.219262171, 49.670072392))
              .id,
          0xb112966aaaaaaaab);
    });
    test('S2CellId.parent', () {
      expect(new S2CellId(0x47a1cbd595522b39).parent(), new S2CellId(0x47a1cbd595522b39).immediateParent());
      expect(new S2CellId(0x47a1cbd595522b39).parent(29), new S2CellId(0x47a1cbd595522b39).immediateParent());
      expect(new S2CellId(0x47a1cbd595522b39).parent(28), new S2CellId(0x47a1cbd595522b39).immediateParent().immediateParent());
      expect(new S2CellId(0x47a1cbd595522b39).parent(28).id, 0x47a1cbd595522b30);
      expect(new S2CellId(0x47a1cbd595522b39).parent(13).level, 13);
    });
    test('S2CellId.operator', () {
      expect(new S2CellId(0xf7a1cbd595522b39) > new S2CellId(0x07a1cbd595522b39), isTrue);
      expect(new S2CellId(0xf7a1cbd595522b39) > new S2CellId(0xe7a1cbd595522b39), isTrue);
      expect(new S2CellId(0x17a1cbd595522b39) > new S2CellId(0x07a1cbd595522b39), isTrue);
      expect(new S2CellId(0xf7a1cbd595522b39) < new S2CellId(0x07a1cbd595522b39), isFalse);
      expect(new S2CellId(0xf7a1cbd595522b39) < new S2CellId(0xe7a1cbd595522b39), isFalse);
      expect(new S2CellId(0x17a1cbd595522b39) < new S2CellId(0x07a1cbd595522b39), isFalse);
    });
    test('S2CellId.toToken', () {
      expect(new S2CellId(0x47a1cbd595522b39).toToken(), "47a1cbd595522b39");
      expect(new S2CellId(0x47a1cbd595522b39).parent(29).toToken(), "47a1cbd595522b3c");
      expect(new S2CellId(0x47a1cbd595522b39).parent(28).toToken(), "47a1cbd595522b3");
    });
  });
}
