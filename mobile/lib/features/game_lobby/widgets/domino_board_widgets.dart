import 'package:flutter/material.dart';
import '../../../core/theme/lamma_theme.dart';

/// لوح الدومينو الملتف تلقائياً (Snake / S-Curve) ليبقى كل الورق ظاهراً على الشاشة بدون Scroll
class SnakeDominoBoard extends StatelessWidget {
  final List<List<int>> board;
  final List<dynamic>? lastPlayedTile;
  final bool showLeftSlot;
  final bool showRightSlot;
  final VoidCallback? onTapLeftSlot;
  final VoidCallback? onTapRightSlot;
  final String emptyMessage;

  const SnakeDominoBoard({
    super.key,
    required this.board,
    this.lastPlayedTile,
    this.showLeftSlot = false,
    this.showRightSlot = false,
    this.onTapLeftSlot,
    this.onTapRightSlot,
    this.emptyMessage = 'الطاولة فاضية — اختر قطعة للبدء 🎯',
  });

  @override
  Widget build(BuildContext context) {
    if (board.isEmpty) {
      if (showRightSlot && onTapRightSlot != null) {
        return Center(
          child: GestureDetector(
            onTap: onTapRightSlot,
            child: const DominoDropSlot(isVertical: false),
          ),
        );
      }
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0;
        final totalItems = board.length + (showLeftSlot ? 1 : 0) + (showRightSlot ? 1 : 0);

        // حساب الحجم المناسب تلقائياً ليبقى كل الورق مرئياً بدون أي تمرير (Zero Scroll)
        double scale = 0.72;
        if (totalItems > 22) {
          scale = 0.44;
        } else if (totalItems > 16) {
          scale = 0.50;
        } else if (totalItems > 10) {
          scale = 0.58;
        }
        if (maxW < 300) {
          scale *= 0.86;
        }

        final tileW = 76.0 * scale;
        final perRow = (maxW / (tileW + 4)).floor().clamp(3, 9);

        final List<Widget> allItems = [];
        if (showLeftSlot && onTapLeftSlot != null) {
          allItems.add(GestureDetector(
            onTap: onTapLeftSlot,
            child: DominoDropSlot(isVertical: false, scale: scale),
          ));
        }

        for (final tile in board) {
          final isDouble = tile[0] == tile[1];
          final isLast = lastPlayedTile != null &&
              lastPlayedTile!.length == 2 &&
              ((lastPlayedTile![0] == tile[0] && lastPlayedTile![1] == tile[1]) ||
                  (lastPlayedTile![0] == tile[1] && lastPlayedTile![1] == tile[0]));

          allItems.add(DominoTileWidget(
            a: tile[0],
            b: tile[1],
            isVertical: isDouble,
            isLastPlayed: isLast,
            scale: scale,
          ));
        }

        if (showRightSlot && onTapRightSlot != null) {
          allItems.add(GestureDetector(
            onTap: onTapRightSlot,
            child: DominoDropSlot(isVertical: false, scale: scale),
          ));
        }

        // تقسيم العناصر إلى صفوف ثعبانية (صف من اليسار لليمين، ثم صف من اليمين لليسار)
        final List<List<Widget>> rows = [];
        for (int i = 0; i < allItems.length; i += perRow) {
          final chunk = allItems.sublist(i, (i + perRow).clamp(0, allItems.length));
          final rowIdx = rows.length;
          rows.add(rowIdx.isOdd ? chunk.reversed.toList() : chunk);
        }

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH * 1.35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(rows.length, (rIdx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: rows[rIdx]
                          .map((w) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: w,
                              ))
                          .toList(),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DominoDropSlot extends StatelessWidget {
  final bool isVertical;
  final double scale;
  const DominoDropSlot({super.key, required this.isVertical, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (isVertical ? 36 : 64) * scale,
      height: (isVertical ? 64 : 36) * scale,
      decoration: BoxDecoration(
        color: LammaColors.gold500.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(7 * scale),
        border: Border.all(color: LammaColors.gold500, width: 1.8),
        boxShadow: [BoxShadow(color: LammaColors.gold500.withValues(alpha: 0.35), blurRadius: 8)],
      ),
      child: Icon(Icons.add_rounded, color: LammaColors.gold500, size: 18 * scale),
    );
  }
}

/// ودجت بلاطة الدومينو ثلاثية الأبعاد بنقاط ملونة
class DominoTileWidget extends StatelessWidget {
  final int a;
  final int b;
  final bool isVertical;
  final bool isLastPlayed;
  final double scale;

  const DominoTileWidget({
    super.key,
    required this.a,
    required this.b,
    this.isVertical = true,
    this.isLastPlayed = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final w = (isVertical ? 44.0 : 80.0) * scale;
    final h = (isVertical ? 84.0 : 42.0) * scale;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8EE),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(
          color: isLastPlayed ? Colors.cyanAccent : const Color(0xFFD6C7AE),
          width: isLastPlayed ? 2.2 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isLastPlayed ? Colors.cyanAccent.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 2),
            blurRadius: isLastPlayed ? 10 : 3,
          ),
        ],
      ),
      child: isVertical
          ? Column(
              children: [
                Expanded(child: _PipFace(value: a, scale: scale)),
                Container(height: 1.5, width: w * 0.75, color: const Color(0xFF9E8E76)),
                Expanded(child: _PipFace(value: b, scale: scale)),
              ],
            )
          : Row(
              children: [
                Expanded(child: _PipFace(value: a, scale: scale)),
                Container(width: 1.5, height: h * 0.75, color: const Color(0xFF9E8E76)),
                Expanded(child: _PipFace(value: b, scale: scale)),
              ],
            ),
    );
  }
}

class _PipFace extends StatelessWidget {
  final int value;
  final double scale;

  const _PipFace({required this.value, required this.scale});

  static const Map<int, List<int>> _pipMap = {
    0: [],
    1: [4],
    2: [0, 8],
    3: [0, 4, 8],
    4: [0, 2, 6, 8],
    5: [0, 2, 4, 6, 8],
    6: [0, 2, 3, 5, 6, 8],
  };

  Color _pipColor(int v) {
    switch (v) {
      case 1:
        return const Color(0xFFD97706);
      case 2:
        return const Color(0xFF2563EB);
      case 3:
        return const Color(0xFF16A34A);
      case 4:
        return const Color(0xFFDC2626);
      case 5:
        return const Color(0xFF9333EA);
      case 6:
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF1F1638);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _pipMap[value] ?? const [];
    final dotSize = 5.4 * scale;

    return Padding(
      padding: EdgeInsets.all(4.2 * scale),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: 9,
        itemBuilder: (_, idx) {
          if (!active.contains(idx)) return const SizedBox.shrink();
          return Center(
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: _pipColor(value),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}
