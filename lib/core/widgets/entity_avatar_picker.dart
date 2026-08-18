import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../network/media_url.dart';
import '../theme/app_colors.dart';

/// An image selected from the device gallery, ready to be uploaded.
class PickedImage {
  const PickedImage({required this.bytes, required this.filename});

  /// Raw file bytes. The backend detects the MIME type from these bytes.
  final Uint8List bytes;

  /// Original file name, including its extension (e.g. `logo.jpg`).
  final String filename;
}

/// Circular avatar with an "Add/Change image" affordance.
///
/// Displays, in priority order, a freshly [pickedImageBytes] preview, the
/// [currentImageUrl] served by the API (resolved through [resolveMediaUrl]), or
/// a fallback [iconData]. Tapping opens the gallery and reports the selection
/// through [onImagePicked]. While [isBusy] is true a spinner replaces the image
/// and picking is disabled.
class EntityAvatarPicker extends StatelessWidget {
  const EntityAvatarPicker({
    required this.iconData,
    this.currentImageUrl,
    this.pickedImageBytes,
    this.onImagePicked,
    this.isBusy = false,
    this.radius = 48,
    super.key,
  });

  final IconData iconData;
  final String? currentImageUrl;
  final Uint8List? pickedImageBytes;
  final ValueChanged<PickedImage>? onImagePicked;
  final bool isBusy;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final resolvedUrl = resolveMediaUrl(currentImageUrl);
    final hasPicked = pickedImageBytes != null;
    final hasImage = hasPicked || resolvedUrl != null;
    final enabled = onImagePicked != null && !isBusy;

    return GestureDetector(
      onTap: enabled ? () => _pickImage(context) : null,
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
            child: isBusy
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.info,
                      ),
                    ),
                  )
                : _buildImage(diameter, resolvedUrl),
          ),
          if (onImagePicked != null) ...<Widget>[
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

  Widget _buildImage(double diameter, String? resolvedUrl) {
    if (pickedImageBytes != null) {
      return Image.memory(
        pickedImageBytes!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
      );
    }
    if (resolvedUrl != null) {
      return Image.network(
        resolvedUrl,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _DefaultIcon(iconData: iconData, size: radius),
      );
    }
    return _DefaultIcon(iconData: iconData, size: radius);
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    onImagePicked?.call(PickedImage(bytes: bytes, filename: file.name));
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
