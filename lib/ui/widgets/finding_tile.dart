import 'package:flutter/material.dart';

import '../../core/finding.dart';
import '../theme.dart';

/// One fired rule, in both display layers.
///
/// The plain-English line is always visible; the technical detail sits behind
/// a "See details" toggle. Both layers live on the same [Finding] object, so a
/// finding can never lose half its explanation on the way to the screen.
///
/// The plain layer always names the pattern actually detected — generic
/// warnings are banned by `docs/design.md` § Do's and Don'ts, because a
/// warning that could apply to any URL teaches the user to dismiss warnings.
class FindingTile extends StatefulWidget {
  const FindingTile({super.key, required this.finding, this.isLast = false});

  final Finding finding;
  final bool isLast;

  @override
  State<FindingTile> createState() => _FindingTileState();
}

class _FindingTileState extends State<FindingTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final finding = widget.finding;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(finding.plain, style: AppType.body)),
              if (finding.points > 0) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  '+${finding.points}',
                  style: AppType.monoDetail,
                  semanticsLabel: 'adds ${finding.points} to the risk score',
                ),
              ],
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(0, 44),
              ),
              child: Text(_expanded ? 'Hide details' : 'See details'),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: SelectableText(
                finding.technical,
                style: AppType.monoDetail,
              ),
            ),
        ],
      ),
    );
  }
}
