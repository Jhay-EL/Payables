import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:io';
import '../utils/material3_color_system.dart';

class ColorPickerScreen extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorSelected;
  final String? currentTitle;
  final Object? currentIcon;
  final String? currentAmount;
  final String? currentDescription;
  final String? currentDueDate;

  const ColorPickerScreen({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
    this.currentTitle,
    this.currentIcon,
    this.currentAmount,
    this.currentDescription,
    this.currentDueDate,
  });

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  late HSVColor pickedHsvColor;
  late TextEditingController hexController;
  late Color selectedColor;

  // Material 3 expressive color system
  Color get backgroundColor {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getSurfaceColor(brightness);
  }

  Color get lightColor {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getSurfaceVariantColor(brightness);
  }

  Color get darkColor {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getOnSurfaceVariantColor(brightness);
  }

  Color get highContrastDarkBlue {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getOnSurfaceColor(brightness);
  }

  Color get highContrastBlue {
    final brightness = Theme.of(context).brightness;
    return Material3ColorSystem.getPrimaryColor(brightness);
  }

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
    pickedHsvColor = HSVColor.fromColor(widget.initialColor);
    hexController = TextEditingController(
      text: widget.initialColor
          .toARGB32()
          .toRadixString(16)
          .substring(2)
          .toUpperCase(),
    );
  }

  @override
  void dispose() {
    hexController.dispose();
    super.dispose();
  }

  void updateColor(HSVColor newHsvColor) {
    if (newHsvColor == pickedHsvColor) return;

    setState(() {
      pickedHsvColor = newHsvColor;
      selectedColor = newHsvColor.toColor();
      final newHex = newHsvColor
          .toColor()
          .toARGB32()
          .toRadixString(16)
          .substring(2)
          .toUpperCase();
      if (hexController.text.toUpperCase() != newHex) {
        hexController.text = newHex;
        hexController.selection = TextSelection.fromPosition(
          TextPosition(offset: hexController.text.length),
        );
      }
    });
  }

  Color get _previewTextColor {
    return selectedColor.computeLuminance() > 0.5
        ? const Color(0xFF111827) // A very dark gray, almost black
        : Colors.white;
  }

  Widget _buildColorPreview(Color selectedColor) {
    final title = widget.currentTitle?.isNotEmpty == true
        ? widget.currentTitle!
        : 'New Payable';
    final description = widget.currentDescription?.isNotEmpty == true
        ? widget.currentDescription!
        : 'Not set';
    final dueDate = widget.currentDueDate?.isNotEmpty == true
        ? widget.currentDueDate!
        : 'Due in 1 day';
    final price = widget.currentAmount?.isNotEmpty == true
        ? '€ ${widget.currentAmount}'
        : '€ 0.00';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: selectedColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon with enhanced styling
            widget.currentIcon is File
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      widget.currentIcon as File,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _previewTextColor.withAlpha(153),
                          _previewTextColor.withAlpha(128),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.currentIcon is IconData
                          ? widget.currentIcon as IconData
                          : Icons.category_rounded,
                      size: 24,
                      color: _previewTextColor,
                    ),
                  ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _previewTextColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _previewTextColor.withAlpha(179),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _previewTextColor.withAlpha(179),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dueDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _previewTextColor.withAlpha(179),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Price with enhanced styling
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _previewTextColor.withAlpha(38),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _previewTextColor.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Text(
                price,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _previewTextColor,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Material3ColorSystem.getSurfaceTintColor(
          Theme.of(context).brightness,
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: highContrastDarkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Color',
          style: TextStyle(
            color: highContrastDarkBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onColorSelected(selectedColor);
              Navigator.pop(context);
            },
            child: Text(
              'Select',
              style: TextStyle(
                color: highContrastDarkBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColorPreview(selectedColor),
            const SizedBox(height: 20),

            // Color Wheel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightColor.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color Wheel',
                    style: TextStyle(
                      color: highContrastDarkBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ColorWheelWidget(
                    currentColor: selectedColor,
                    onColorChanged: (wheelColor) {
                      final wheelHsv = HSVColor.fromColor(wheelColor);
                      updateColor(
                        pickedHsvColor
                            .withHue(wheelHsv.hue)
                            .withSaturation(wheelHsv.saturation),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Brightness Slider
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightColor.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brightness',
                    style: TextStyle(
                      color: highContrastDarkBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.brightness_4_rounded,
                        color: darkColor.withAlpha(179),
                        size: 20,
                      ),
                      Expanded(
                        child: Slider(
                          value: pickedHsvColor.value,
                          min: 0.0,
                          max: 1.0,
                          activeColor: highContrastBlue,
                          inactiveColor: highContrastBlue.withValues(
                            alpha: 0.3,
                          ),
                          onChanged: (value) {
                            updateColor(pickedHsvColor.withValue(value));
                          },
                        ),
                      ),
                      Icon(
                        Icons.brightness_7_rounded,
                        color: darkColor.withAlpha(179),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hex Input
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightColor.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hex Code',
                    style: TextStyle(
                      color: highContrastDarkBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hexController,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: highContrastDarkBlue,
                      fontFamily: 'monospace',
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      prefixText: '#',
                      counterText: '',
                      filled: true,
                      fillColor: backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: selectedColor, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 6) {
                        try {
                          final newColor = Color(
                            int.parse('FF$value', radix: 16),
                          );
                          updateColor(HSVColor.fromColor(newColor));
                        } catch (e) {
                          // Ignore invalid hex codes
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

class _ColorWheelWidget extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  const _ColorWheelWidget({
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(currentColor);
    final angle = hsv.hue * 3.14159 / 180;
    final radius = 120.0; // Half of the container size (240/2)
    final distance = hsv.saturation * radius;

    final selectorX = radius + distance * math.cos(angle);
    final selectorY = radius + distance * math.sin(angle);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ],
                  ),
                ),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final localPosition = renderBox.globalToLocal(
                      details.globalPosition,
                    );
                    final center = renderBox.size.center(Offset.zero);
                    final offset = localPosition - center;
                    final angle = offset.direction;
                    final distance = offset.distance;
                    final radius = renderBox.size.width / 2;

                    if (distance <= radius) {
                      final hue = (angle * 180 / 3.14159 + 360) % 360;
                      final saturation = (distance / radius).clamp(0.0, 1.0);
                      final hsv = HSVColor.fromColor(currentColor);
                      final newColor = hsv
                          .withHue(hue)
                          .withSaturation(saturation)
                          .toColor();
                      onColorChanged(newColor);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              )
              .scale(
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
              )
              .then(delay: const Duration(seconds: 1))
              .shimmer(
                duration: const Duration(milliseconds: 3000),
                color: Colors.white.withValues(alpha: 0.2),
                size: 3.0,
              ),
          // Round selector indicator
          Positioned(
            left: selectorX - 10, // Half of selector size (20/2)
            top: selectorY - 10,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
