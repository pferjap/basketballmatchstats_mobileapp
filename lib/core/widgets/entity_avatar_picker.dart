import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EntityAvatarPicker extends StatelessWidget {
  const EntityAvatarPicker({
    required this.iconData,
    this.currentImageUrl,
    this.onImageSelected,
    this.radius = 48,
    super.key,
  });

  final IconData iconData;
  final String? currentImageUrl;
  final ValueChanged<String>? onImageSelected;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final hasImage =
        currentImageUrl != null && currentImageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onImageSelected != null ? () => _pickImage(context) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.network(
                    currentImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _DefaultIcon(iconData: iconData, size: radius),
                  )
                : _DefaultIcon(iconData: iconData, size: radius),
          ),
          if (onImageSelected != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              hasImage ? 'Cambiar imagen' : 'Añadir imagen',
              style: const TextStyle(
                color: AppColors.info,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _pickImage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La carga de imágenes estará disponible próximamente.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _DefaultIcon extends StatelessWidget {
  const _DefaultIcon({required this.iconData, required this.size});

  final IconData iconData;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(iconData, size: size, color: AppColors.textSecondary);
  }
}
