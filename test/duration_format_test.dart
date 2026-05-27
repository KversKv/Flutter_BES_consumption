import 'package:bes_consumption/widgets/duration_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('duration formatter adapts us ms and s units', () {
    expect(formatDurationUsAuto(999), '999 us');
    expect(formatDurationUsAuto(1000), '1 ms');
    expect(formatDurationUsAuto(1500), '1.5 ms');
    expect(formatDurationUsAuto(999999), '999.999 ms');
    expect(formatDurationUsAuto(1000000), '1 s');
    expect(formatDurationUsAuto(1250000), '1.25 s');
  });
}
