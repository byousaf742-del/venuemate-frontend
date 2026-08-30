import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../sign_up_login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthRoleSelectorWidget extends StatelessWidget {
  final UserRole selectedRole;
  final Function(UserRole) onRoleSelected;

  const AuthRoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign in as:',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                context,
                role: UserRole.customer,
                icon: Icons.person_search_rounded,
                title: 'Customer',
                subtitle: 'Find & book venues',
                isSelected: selectedRole == UserRole.customer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildRoleCard(
                context,
                role: UserRole.owner,
                icon: Icons.store_rounded,
                title: 'Venue Owner',
                subtitle: 'Manage my venues',
                isSelected: selectedRole == UserRole.owner,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required UserRole role,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onRoleSelected(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLighter : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primary : AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
