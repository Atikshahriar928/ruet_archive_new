import 'package:flutter/material.dart';

// RUET Theme Colors
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);
const Color blue500 = Color(0xFF3B82F6);

class ItemContextMenu extends StatelessWidget {
  final String itemTitle;
  final String itemType; // "LOST", "FOUND", "CART", "SELLING"
  final VoidCallback onEdit;
  final VoidCallback onMarkAction;
  final VoidCallback onDelete;

  const ItemContextMenu({
    super.key,
    required this.itemTitle,
    required this.itemType,
    required this.onEdit,
    required this.onMarkAction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SELECTED ITEM",
              style: TextStyle(
                color: zinc500,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              itemTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ..._buildActionItems(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionItems(BuildContext context) {
    switch (itemType) {
      case "LOST":
      case "FOUND":
        return [
          _contextMenuItem(
            icon: Icons.edit_outlined,
            label: "Edit Details",
            iconColor: blue500,
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          const SizedBox(height: 16),
          _contextMenuItem(
            icon: Icons.check_circle_outline,
            label: "Mark as Resolved",
            iconColor: emerald500,
            onTap: () {
              Navigator.pop(context);
              onMarkAction();
            },
          ),
          const SizedBox(height: 16),
          _contextMenuItem(
            icon: Icons.delete_outline,
            label: "Delete Item",
            iconColor: const Color(0xFFEF4444),
            isRed: true,
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ];
      case "CART":
        return [
          _contextMenuItem(
            icon: Icons.shopping_cart_checkout,
            label: "Mark as Purchased",
            iconColor: emerald500,
            onTap: () {
              Navigator.pop(context);
              onMarkAction();
            },
          ),
          const SizedBox(height: 16),
          _contextMenuItem(
            icon: Icons.delete_sweep_outlined,
            label: "Discard Item",
            iconColor: const Color(0xFFEF4444),
            isRed: true,
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ];
      case "SELLING":
        return [
          _contextMenuItem(
            icon: Icons.edit_outlined,
            label: "Edit Details",
            iconColor: blue500,
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          const SizedBox(height: 16),
          _contextMenuItem(
            icon: Icons.sell_outlined,
            label: "Mark as Sold",
            iconColor: emerald500,
            onTap: () {
              Navigator.pop(context);
              onMarkAction();
            },
          ),
          const SizedBox(height: 16),
          _contextMenuItem(
            icon: Icons.delete_outline,
            label: "Delete Item",
            iconColor: const Color(0xFFEF4444),
            isRed: true,
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ];
      default:
        return [];
    }
  }

  Widget _contextMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    bool isRed = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              color: isRed ? const Color(0xFFEF4444) : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
