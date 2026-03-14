import 'package:flutter_test/flutter_test.dart';
import 'package:voice_growth_archipelago/src/core/utils/icon_catalog.dart';

void main() {
  test('legacy meditation svg maps to mood icon', () {
    const String svg =
        '<path stroke-linecap="round" stroke-linejoin="round" d="M14.828 14.828a4 4 0 01-5.656 0" />';
    expect(HabitIconCatalog.iconKeyFromLegacySvg(svg), HabitIconKey.mood.name);
  });
}
