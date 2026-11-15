import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ifest_app/models/booking.dart';
import 'package:ifest_app/services/review_service.dart';
import 'package:ifest_app/theme/app_theme.dart';

class ReviewBottomSheet extends StatefulWidget {
  final Booking booking;

  const ReviewBottomSheet({super.key, required this.booking});

  static Future<void> show(BuildContext context, Booking booking) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewBottomSheet(booking: booking),
    );
  }

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final Map<int, String> _ratingLabels = {
    5: 'Excelente! Adorei tudo 😍',
    4: 'Muito bom! Recomendo 🙂',
    3: 'Bom, atendeu ao esperado 😐',
    2: 'Razoável, precisa melhorar 😕',
    1: 'Muito abaixo do esperado 😞',
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ReviewService().submitReview(
        booking: widget.booking,
        rating: _selectedRating.toDouble(),
        comment: _commentController.text.trim(),
        user: user,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Obrigado pela sua avaliação! ⭐')),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar avaliação: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra superior de puxar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDarkMode ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Ícone festivo
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: AppTheme.headerGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.secondaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.star1,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Avalie o Serviço Prestado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Card informativo do serviço
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.booking.serviceTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: context.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.booking.businessName != null &&
                      widget.booking.businessName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Fornecedor: ${widget.booking.businessName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Seletor de Estrelas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = starValue <= _selectedRating;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = starValue;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isSelected ? Colors.amber : Colors.grey.shade400,
                        size: 38,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            // Rótulo do sentimento
            Text(
              _ratingLabels[_selectedRating] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _selectedRating >= 4
                    ? Colors.green
                    : _selectedRating == 3
                        ? Colors.amber.shade800
                        : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),

            // Campo de comentário opcional
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Conte como foi sua experiência (opcional)...',
                hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                filled: true,
                fillColor: context.backgroundColor,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.secondaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botão Enviar Avaliação
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Enviar Avaliação',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Lembrar mais tarde
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: Text(
                'Lembrar mais tarde',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
