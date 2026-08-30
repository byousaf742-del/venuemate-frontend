import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum VenueStatus { available, booked, pending, suspended }

enum BookingStatus { confirmed, pending, cancelled, completed }

enum BidStatus { pending, accepted, rejected, negotiating }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 11,
  });

  factory StatusBadgeWidget.venueStatus(VenueStatus status) {
    switch (status) {
      case VenueStatus.available:
        return StatusBadgeWidget(
          label: 'Available',
          backgroundColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
        );
      case VenueStatus.booked:
        return StatusBadgeWidget(
          label: 'Booked',
          backgroundColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
        );
      case VenueStatus.pending:
        return StatusBadgeWidget(
          label: 'Pending',
          backgroundColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFF57C00),
        );
      case VenueStatus.suspended:
        return StatusBadgeWidget(
          label: 'Suspended',
          backgroundColor: const Color(0xFFF3E5F5),
          textColor: const Color(0xFF6A1B9A),
        );
    }
  }

  factory StatusBadgeWidget.bookingStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return StatusBadgeWidget(
          label: 'Confirmed',
          backgroundColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
        );
      case BookingStatus.pending:
        return StatusBadgeWidget(
          label: 'Pending',
          backgroundColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFF57C00),
        );
      case BookingStatus.cancelled:
        return StatusBadgeWidget(
          label: 'Cancelled',
          backgroundColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
        );
      case BookingStatus.completed:
        return StatusBadgeWidget(
          label: 'Completed',
          backgroundColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF1565C0),
        );
    }
  }

  factory StatusBadgeWidget.bidStatus(BidStatus status) {
    switch (status) {
      case BidStatus.pending:
        return StatusBadgeWidget(
          label: 'Pending',
          backgroundColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFF57C00),
        );
      case BidStatus.accepted:
        return StatusBadgeWidget(
          label: 'Accepted',
          backgroundColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
        );
      case BidStatus.rejected:
        return StatusBadgeWidget(
          label: 'Rejected',
          backgroundColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
        );
      case BidStatus.negotiating:
        return StatusBadgeWidget(
          label: 'Negotiating',
          backgroundColor: const Color(0xFFFCE4EC),
          textColor: const Color(0xFFAD1457),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
