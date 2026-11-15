import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/models/review.dart';
import 'package:ifest_business/theme/app_theme.dart';

class ReviewsScreen extends StatelessWidget {
  final Business business;

  const ReviewsScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Avaliações dos Clientes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('businessId', isEqualTo: business.id)
            .orderBy('created', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar avaliações.',
                style: TextStyle(color: Colors.red.shade400),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final reviews = docs
              .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          if (reviews.isEmpty) {
            return _buildEmptyState(context);
          }

          final totalCount = reviews.length;
          final averageRating = totalCount > 0
              ? reviews.map((r) => r.rating).fold<double>(0.0, (a, b) => a + b) / totalCount
              : 0.0;

          final Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          for (final r in reviews) {
            final star = r.rating.round().clamp(1, 5);
            starCounts[star] = (starCounts[star] ?? 0) + 1;
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildRatingSummary(context, averageRating, totalCount, starCounts),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comentários Recebidos',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.secondaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalCount total',
                      style: TextStyle(
                        color: context.secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...reviews.map((r) => _buildReviewCard(context, r)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.secondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.star,
                size: 40,
                color: context.secondaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhuma avaliação ainda',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quando seus clientes concluírem os serviços contratados, as notas e comentários aparecerão aqui.',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummary(
    BuildContext context,
    double average,
    int count,
    Map<int, int> starCounts,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < average.floor()
                        ? Icons.star_rounded
                        : (index < average ? Icons.star_half_rounded : Icons.star_border_rounded),
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '$count ${count == 1 ? "avaliação" : "avaliações"}',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          // Barras de distribuição real
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (index) {
              final starNum = 5 - index;
              final starCount = starCounts[starNum] ?? 0;
              final factor = count > 0 ? (starCount / count).clamp(0.0, 1.0) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    Text(
                      '$starNum ★',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 110,
                      height: 7,
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? Colors.white12 : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: factor,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review) {
    final date = review.created.toDate();
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: context.secondaryColor.withValues(
                      alpha: context.isDarkMode ? 0.25 : 0.12,
                    ),
                    backgroundImage: review.authorPhoto != null && review.authorPhoto!.isNotEmpty
                        ? NetworkImage(review.authorPhoto!)
                        : null,
                    child: review.authorPhoto == null || review.authorPhoto!.isEmpty
                        ? Text(
                            review.authorName.isNotEmpty
                                ? review.authorName[0].toUpperCase()
                                : 'C',
                            style: TextStyle(
                              color: context.secondaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating.floor()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 15,
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dateStr,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (review.serviceTitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Serviço: ${review.serviceTitle}',
                style: TextStyle(
                  color: context.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
