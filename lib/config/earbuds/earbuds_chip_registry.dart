import '../../models/earbuds.dart';
import 'chips/chip_1607.dart';
import 'chips/chip_1503p.dart';
import 'chips/chip_1702.dart';
import 'chips/chip_1605.dart';
import 'chips/chip_1502p.dart';
import 'chips/chip_1307p.dart';
import 'chips/chip_1307.dart';
import 'chips/chip_1306p.dart';
import 'chips/chip_1700.dart';
import 'chips/chip_1603.dart';
import 'chips/chip_1600.dart';
import 'chips/chip_1503.dart';
import 'chips/chip_1502x.dart';
import 'chips/chip_1501p.dart';
import 'chips/chip_1501.dart';
import 'chips/chip_1306.dart';

/// 所有已建模的耳机芯片，按数据表顺序。
/// 新增芯片：在 `chips/` 下新建 `chip_xxx.dart`，然后在此处 import + 追加到列表。
const List<EarbudsChip> kAllChips = [
  kChip1607,
  kChip1503p,
  kChip1702,
  kChip1605,
  kChip1502p,
  kChip1307p,
  kChip1307,
  kChip1306p,
  kChip1700,
  kChip1603,
  kChip1600,
  kChip1503,
  kChip1502x,
  kChip1501p,
  kChip1501,
  kChip1306,
];
