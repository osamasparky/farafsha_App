import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/lamma_theme.dart';

class _PlacedNode {
  final double x;
  final double y;
  final double w;
  final double h;
  final bool isVertical;
  final int a;
  final int b;
  final bool isLast;

  _PlacedNode({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.isVertical,
    required this.a,
    required this.b,
    required this.isLast,
  });
}

/// لوح الدومينو المتصل بشكل مربع/ثعباني (ضلعين أفقيين مع ضلع عمودي من قطعتين على الأقل) بدون Scroll
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
        final availW = constraints.maxWidth.isFinite ? constraints.maxWidth : 340.0;
        final availH = constraints.maxHeight.isFinite ? constraints.maxHeight : 220.0;
        final isPortrait = availH > availW;

        const double longSide = 68.0;
        const double shortSide = 36.0;
        const double gap = 3.0;

        // عدد البلاطات في الضلع الأفقي قبل الالتفاف بضلع عمودي من 2 ورقة على الأقل
        final int rowCap = isPortrait ? 4 : 7;
        const int legCap = 2; // ضلع المربع يحتوي على ورقتين على الأقل قبل اللف

        // حساب مواضع جميع البلاطات كسلسلة متصلة تماماً
        final List<_PlacedNode> nodes = [];
        double curX = 0;
        double curY = 0;
        // 0 = يمين، 1 = أسفل (ضلع يمين)، 2 = يسار، 3 = أسفل (ضلع يسار)
        int dir = 0;
        int stepInSegment = 0;

        for (int i = 0; i < board.length; i++) {
          final tile = board[i];
          final isDouble = tile[0] == tile[1];
          final isLast = lastPlayedTile != null &&
              lastPlayedTile!.length == 2 &&
              ((lastPlayedTile![0] == tile[0] && lastPlayedTile![1] == tile[1]) ||
                  (lastPlayedTile![0] == tile[1] && lastPlayedTile![1] == tile[0]));

          // في المسار الأفقي: الدبل يكون عمودياً والعادي أفقياً
          // في المسار العمودي (ضلع المربع): الدبل يكون أفقياً والعادي عمودياً
          final bool verticalTile = (dir == 0 || dir == 2) ? isDouble : !isDouble;
          final double w = verticalTile ? shortSide : longSide;
          final double h = verticalTile ? longSide : shortSide;

          // عكس ترتيب الأرقام في المسار العكسي (من اليمين لليسار) للحفاظ على تطابق الأرقام بصرياً
          final int dispA = (dir == 2 && !verticalTile) ? tile[1] : tile[0];
          final int dispB = (dir == 2 && !verticalTile) ? tile[0] : tile[1];

          double drawX = curX;
          double drawY = curY;

          if (dir == 0) {
            // توسيط الدبل عمودياً على خط السلسلة الأفقي
            drawY = curY + (shortSide - h) / 2;
            nodes.add(_PlacedNode(x: drawX, y: drawY, w: w, h: h, isVertical: verticalTile, a: dispA, b: dispB, isLast: isLast));
            stepInSegment++;
            if (stepInSegment >= rowCap) {
              // الانتقال للضلع العمودي لأسفل بمحاذاة نهاية البلاطة الأخيرة
              dir = 1;
              stepInSegment = 0;
              curX = drawX + w - shortSide;
              curY = math.max(curY + shortSide, drawY + h) + gap;
            } else {
              curX = drawX + w + gap;
            }
          } else if (dir == 1) {
            // ضلع عمودي لأسفل (ورقتين على الأقل)
            nodes.add(_PlacedNode(x: drawX, y: drawY, w: w, h: h, isVertical: verticalTile, a: dispA, b: dispB, isLast: isLast));
            stepInSegment++;
            if (stepInSegment >= legCap) {
              // الانعطاف لليسار
              dir = 2;
              stepInSegment = 0;
              curX = drawX + w - longSide - gap - shortSide;
              curY = drawY + h - shortSide;
              // نبدأ البلاطة التالية مباشرة على يسار آخر بلاطة في الضلع العمودي
              curX = drawX - gap;
            } else {
              curY = drawY + h + gap;
            }
          } else if (dir == 2) {
            // مسار أفقي من اليمين لليسار
            drawX = curX - w;
            drawY = curY + (shortSide - h) / 2;
            nodes.add(_PlacedNode(x: drawX, y: drawY, w: w, h: h, isVertical: verticalTile, a: dispA, b: dispB, isLast: isLast));
            stepInSegment++;
            if (stepInSegment >= rowCap) {
              // الانعطاف لأسفل من الطرف الأيسر
              dir = 3;
              stepInSegment = 0;
              curX = drawX;
              curY = math.max(curY + shortSide, drawY + h) + gap;
            } else {
              curX = drawX - gap;
            }
          } else {
            // ضلع عمودي لأسفل من اليسار
            nodes.add(_PlacedNode(x: drawX, y: drawY, w: w, h: h, isVertical: verticalTile, a: dispA, b: dispB, isLast: isLast));
            stepInSegment++;
            if (stepInSegment >= legCap) {
              // الانعطاف لليمين
              dir = 0;
              stepInSegment = 0;
              curX = drawX + w + gap;
              curY = drawY + h - shortSide;
            } else {
              curY = drawY + h + gap;
            }
          }
        }

        // إضافة فتحات التوصيل المنقطة (Drop Slots) عند الطرفين
        final first = nodes.first;
        final last = nodes.last;

        double minX = nodes.map((n) => n.x).reduce(math.min);
        double minY = nodes.map((n) => n.y).reduce(math.min);
        double maxX = nodes.map((n) => n.x + n.w).reduce(math.max);
        double maxY = nodes.map((n) => n.y + n.h).reduce(math.max);

        const double slotW = 52;
        const double slotH = 34;

        final double leftSlotX = first.x - slotW - gap;
        final double leftSlotY = first.y + (first.h - slotH) / 2;

        double rightSlotX;
        double rightSlotY;
        if (dir == 0) {
          rightSlotX = last.x + last.w + gap;
          rightSlotY = last.y + (last.h - slotH) / 2;
        } else if (dir == 2) {
          rightSlotX = last.x - slotW - gap;
          rightSlotY = last.y + (last.h - slotH) / 2;
        } else {
          rightSlotX = last.x + (last.w - slotH) / 2;
          rightSlotY = last.y + last.h + gap;
        }

        if (showLeftSlot) {
          minX = math.min(minX, leftSlotX);
          minY = math.min(minY, leftSlotY);
        }
        if (showRightSlot) {
          maxX = math.max(maxX, rightSlotX + slotW);
          maxY = math.max(maxY, rightSlotY + slotH);
          minX = math.min(minX, rightSlotX);
        }

        final canvasW = math.max(100.0, maxX - minX + 16);
        final canvasH = math.max(80.0, maxY - minY + 16);
        final offX = -minX + 8;
        final offY = -minY + 8;

        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: canvasW,
              height: canvasH,
              child: Stack(
                children: [
                  for (final n in nodes)
                    Positioned(
                      left: n.x + offX,
                      top: n.y + offY,
                      child: DominoTileWidget(
                        a: n.a,
                        b: n.b,
                        isVertical: n.isVertical,
                        isLastPlayed: n.isLast,
                        scale: 0.84,
                      ),
                    ),
                  if (showLeftSlot && onTapLeftSlot != null)
                    Positioned(
                      left: leftSlotX + offX,
                      top: leftSlotY + offY,
                      child: GestureDetector(
                        onTap: onTapLeftSlot,
                        child: const DominoDropSlot(isVertical: false, scale: 0.85),
                      ),
                    ),
                  if (showRightSlot && onTapRightSlot != null)
                    Positioned(
                      left: rightSlotX + offX,
                      top: rightSlotY + offY,
                      child: GestureDetector(
                        onTap: onTapRightSlot,
                        child: DominoDropSlot(isVertical: dir == 1 || dir == 3, scale: 0.85),
                      ),
                    ),
                ],
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
      width: (isVertical ? 36 : 60) * scale,
      height: (isVertical ? 60 : 36) * scale,
      decoration: BoxDecoration(
        color: LammaColors.gold500.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(7 * scale),
        border: Border.all(color: LammaColors.gold500, width: 1.8),
        boxShadow: [BoxShadow(color: LammaColors.gold500.withValues(alpha: 0.4), blurRadius: 8)],
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
    final w = (isVertical ? 42.8 : 80.9) * scale;
    final h = (isVertical ? 80.9 : 42.8) * scale;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8EE),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(
          color: isLastPlayed ? Colors.cyanAccent : const Color(0xFFD6C7AE),
          width: isLastPlayed ? 2.2 : 1.3,
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
                Container(height: 1.5, width: w * 0.72, color: const Color(0xFF9E8E76)),
                Expanded(child: _PipFace(value: b, scale: scale)),
              ],
            )
          : Row(
              children: [
                Expanded(child: _PipFace(value: a, scale: scale)),
                Container(width: 1.5, height: h * 0.72, color: const Color(0xFF9E8E76)),
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
    final dotSize = 5.2 * scale;

    return Padding(
      padding: EdgeInsets.all(4.0 * scale),
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
