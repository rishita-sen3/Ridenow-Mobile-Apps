import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatSubItem {
  final String label;
  final String value;
  final Color dotColor;
  final VoidCallback? onTap;

  StatSubItem({required this.label, required this.value, required this.dotColor, this.onTap});
}

class StatCard extends StatelessWidget {
  final String title;
  final String totalValue;
  final List<StatSubItem> subItems;
  final bool isDark;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.totalValue,
    required this.subItems,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212529) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white70 : const Color(0xFF6c757d),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalValue,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : const Color(0xFF212529),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: subItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: InkWell(
                        onTap: item.onTap,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (item.dotColor != Colors.transparent) ...[
                                    Icon(Icons.circle, size: 8, color: item.dotColor),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    item.label,
                                    style: GoogleFonts.inter(
                                      color: isDark ? Colors.white70 : const Color(0xFF6c757d),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                item.value,
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white : const Color(0xFF212529),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
