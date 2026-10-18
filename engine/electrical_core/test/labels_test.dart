import 'package:electrical_core/electrical_core.dart';
import 'package:norms_data/norms_data.dart';
import 'package:test/test.dart';

void main() {
  group('protection device summary', () {
    const rcd = RcdResult(residualMa: 30, type: 'A', reasons: []);
    final List<(ProtectionDevice, RcdResult?, String)> cases = [
      (ProtectionDevice.mcb, null, 'Автомат'),
      (ProtectionDevice.rcbo, rcd, 'Дифавтомат · 30 мА, тип A'),
      (
        ProtectionDevice.mcbAndRcd,
        const RcdResult(residualMa: 30, type: 'A', reasons: [], ratedA: 25),
        'Автомат + УЗО 25 А · 30 мА, тип A',
      ),
      (
        ProtectionDevice.mcbUnderGroupRcd,
        const RcdResult(residualMa: 30, type: 'A', reasons: [], groupId: 'Q2'),
        'Автомат · УЗО Q2',
      ),
    ];
    for (final (device, rcdResult, expected) in cases) {
      test(device.name, () {
        final protection = ProtectionResult(
          device: device,
          breakerA: 16,
          curve: BreakerCurve.c,
          poles: 1,
          breakerSource: ValueSource.automatic,
          rcd: rcdResult,
        );
        expect(protection.deviceSummary, expected);
        expect(protection.label, 'C16');
      });
    }
  });
}
