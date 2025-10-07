import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/fritids_provider.dart';
import '../../../domain/models/pass_type.dart';

class PassTypeSelector extends StatelessWidget {
  const PassTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final fritidsProvider = context.watch<FritidsProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPassTypeButton(
              context,
              PassType.fm,
              fritidsProvider.selectedPassType == PassType.fm,
              () => fritidsProvider.selectPassType(PassType.fm),
              screenWidth,
            ),
            const SizedBox(width: 4),
            _buildPassTypeButton(
              context,
              PassType.em,
              fritidsProvider.selectedPassType == PassType.em,
              () => fritidsProvider.selectPassType(PassType.em),
              screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassTypeButton(
    BuildContext context,
    PassType passType,
    bool isSelected,
    VoidCallback onTap,
    double screenWidth,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(245, 142, 11, 1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              passType.displayName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              passType.fullDisplayName,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
