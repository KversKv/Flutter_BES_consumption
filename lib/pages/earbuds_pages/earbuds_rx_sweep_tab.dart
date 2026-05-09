part of '../earbuds_compare_page.dart';

class _RxSweepTab extends StatelessWidget {
  const _RxSweepTab();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return _EmptyHint(hint: s.ebNoData);
  }
}
