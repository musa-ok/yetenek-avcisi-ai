import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _card = Color(0xFF151C2B);
const _bone = Color(0x14FFFFFF);
const _shimmerHighlight = Color(0x33FFFFFF);

/// Tek parça iskelet bloğu (shimmer).
class SkeletonBone extends StatelessWidget {
  const SkeletonBone({
    super.key,
    this.width,
    this.height = 12,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _bone,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: _shimmerHighlight);
  }
}

/// Öne çıkan yetenekler carousel iskeleti (3 kart).
class ScoutHomeCarouselSkeleton extends StatelessWidget {
  const ScoutHomeCarouselSkeleton({super.key, required this.horizontal});

  final double horizontal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 22),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const _CarouselCardSkeleton(),
      ),
    );
  }
}

class _CarouselCardSkeleton extends StatelessWidget {
  const _CarouselCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 174,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonBone(width: 36, height: 28, borderRadius: 8),
              const SkeletonBone(width: 40, height: 28, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonBone(width: 120, height: 16, borderRadius: 6),
          const SizedBox(height: 8),
          const SkeletonBone(width: 90, height: 12, borderRadius: 6),
          const Spacer(),
          const SkeletonBone(width: 72, height: 10, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Scout ana sayfa — kayıtlı oyuncular önizleme satırları.
class ScoutHomeListSkeleton extends StatelessWidget {
  const ScoutHomeListSkeleton({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rowCount; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          const _PlayerRowSkeleton(),
        ],
      ],
    );
  }
}

/// Futbolcu ana sayfa — birleşik istatistik kartı iskeleti.
class PlayerHomeMergedStatsSkeleton extends StatelessWidget {
  const PlayerHomeMergedStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SkeletonBone(width: 180, height: 20, borderRadius: 6),
        const SizedBox(height: 10),
        const SkeletonBone(width: 140, height: 12, borderRadius: 6),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              const SkeletonBone(width: 100, height: 12),
              const SizedBox(height: 16),
              const SkeletonBone(width: 132, height: 132, borderRadius: 66),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: List.generate(
                  6,
                  (_) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F19),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBone(width: 24, height: 24, borderRadius: 6),
                        Spacer(),
                        SkeletonBone(width: 48, height: 22, borderRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerRowSkeleton extends StatelessWidget {
  const _PlayerRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const SkeletonBone(width: 40, height: 40, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBone(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonBone(width: 100, height: 11, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonBone(width: 36, height: 28, borderRadius: 8),
        ],
      ),
    );
  }
}
