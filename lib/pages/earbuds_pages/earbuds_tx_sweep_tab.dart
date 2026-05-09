part of '../earbuds_compare_page.dart';

class _TxSweepTab extends StatelessWidget {
  const _TxSweepTab();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return _EmptyHint(hint: s.ebNoData);
  }
}
