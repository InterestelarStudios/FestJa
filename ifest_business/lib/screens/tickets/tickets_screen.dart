import 'package:flutter/material.dart';
import 'package:ifest_business/models/event.dart';
import 'package:ifest_business/theme/app_theme.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Show one active ticket for demonstration, using the mock event details
    final ticketEvent = mockEvents[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Ingressos'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Próximo evento',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Visual Ticket Container
            Card(
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipPath(
                clipper: TicketClipper(),
                child: Container(
                  color: context.surfaceColor,
                  child: Column(
                    children: [
                      // Top Half: Event Image & Title
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(ticketEvent.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      // Bottom Half: Ticket Details
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticketEvent.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use this ticket and scan it at the entrance gate.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                            ),
                            
                            const SizedBox(height: 24),
                            Divider(height: 1, color: Theme.of(context).dividerColor),
                            const SizedBox(height: 20),
                            
                            // Ticket Meta Information
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetaItem(context, 'ORDER ID', '#81329'),
                                _buildMetaItem(context, 'PRICE', '\$20', isPaid: true),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetaItem(context, 'DATE', 'June 20, 2026'),
                                _buildMetaItem(context, 'TIME', '20:00 PM'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetaItem(context, 'VENUE', ticketEvent.location),
                                _buildMetaItem(context, 'SEAT', '48 D'),
                              ],
                            ),
                            
                            const SizedBox(height: 28),
                            
                            // Barcode simulation
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    height: 56,
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          'https://upload.wikimedia.org/wikipedia/commons/e/e9/UPC-A-barcode.svg',
                                        ),
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '9HF930CNX38...3E72',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          letterSpacing: 2,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(BuildContext context, String label, String value, {bool isPaid = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.textMuted,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        if (isPaid)
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
      ],
    );
  }
}

// Custom Clipper to shape the card into a physical ticket style with side cutouts
class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    
    // Add side cutouts (punches) at a specific vertical height (around the divider line)
    // The cutouts will be at Y = 160 (which is the height of the top image)
    double cutoutY = 160.0;
    double radius = 12.0;
    
    // Left Cutout
    var leftPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(0.0, cutoutY), radius: radius),
        -1.57, // Start angle
        3.14,  // Sweep angle
      );
    
    // Right Cutout
    var rightPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(size.width, cutoutY), radius: radius),
        1.57,
        3.14,
      );
    
    // Subtract the arcs from the main path
    final pathWithoutLeft = Path.combine(PathOperation.difference, path, leftPath);
    return Path.combine(PathOperation.difference, pathWithoutLeft, rightPath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
