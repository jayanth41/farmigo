
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

const Color _borderSoft = Color(0xFFE6E6E6);

typedef PromoSearchCallback = void Function(Map<String, dynamic> criteria);

class PromoBox extends StatefulWidget {
  final String category;
  final PromoSearchCallback? onFind;

  const PromoBox({super.key, required this.category, this.onFind});

  @override
  State<PromoBox> createState() => _PromoBoxState();
}

class _PromoBoxState extends State<PromoBox> {
  final TextEditingController _locationController = TextEditingController();
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final first = isStart ? now : (_checkIn ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(_checkIn!)) _checkOut = null;
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  void _openGuestSelector() {
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (c, setS) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Adults', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Row(children: [
                        IconButton(onPressed: () => setS(() => _adults = (_adults - 1).clamp(1, 20)), icon: const Icon(Icons.remove_circle_outline)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text('$_adults')),
                        IconButton(onPressed: () => setS(() => _adults = (_adults + 1).clamp(1, 20)), icon: const Icon(Icons.add_circle_outline)),
                      ])
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Children', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Row(children: [
                        IconButton(onPressed: () => setS(() => _children = (_children - 1).clamp(0, 10)), icon: const Icon(Icons.remove_circle_outline)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text('$_children')),
                        IconButton(onPressed: () => setS(() => _children = (_children + 1).clamp(0, 10)), icon: const Icon(Icons.add_circle_outline)),
                      ])
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done')),
                  ),
                ],
              ),
            );
          });
        }).whenComplete(() => setState(() {}));
  }

  String _guestsLabel() => '$_adults Adults${_children > 0 ? ', $_children Children' : ''}';

  @override
  Widget build(BuildContext context) {
    // Build UI to match the provided SearchCard exactly
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Location'),
          _locationInput(),
          const SizedBox(height: 16),

          _label('Check-in'),
          _dateInput(label: 'Check-in', isStart: true, icon: Icons.calendar_today_outlined, placeholder: 'Select date'),
          const SizedBox(height: 16),

          _label('Check-out'),
          _dateInput(label: 'Check-out', isStart: false, icon: Icons.calendar_today_outlined, placeholder: 'Select date'),
          const SizedBox(height: 16),

          _label('Guests'),
          _guestsInput(),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                final criteria = {
                  'location': _locationController.text,
                  'checkIn': _checkIn?.toIso8601String(),
                  'checkOut': _checkOut?.toIso8601String(),
                  'adults': _adults,
                  'children': _children,
                  'category': widget.category,
                };
                if (widget.onFind != null) widget.onFind!(criteria);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text(
                'Search',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      ),
    );
  }

  Widget _locationInput() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: _borderSoft),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: AppColors.iconGrey, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _locationController,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search destination, farmhouse',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateInput({required bool isStart, required String label, required IconData icon, required String placeholder}) {
    final dateText = isStart ? (_checkIn != null ? '${_checkIn!.day}/${_checkIn!.month}/${_checkIn!.year}' : placeholder) : (_checkOut != null ? '${_checkOut!.day}/${_checkOut!.month}/${_checkOut!.year}' : placeholder);
    return InkWell(
      onTap: () => _pickDate(context, isStart),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: _borderSoft), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(child: Text(dateText, style: const TextStyle(color: AppColors.textMuted, fontSize: 15))),
          ],
        ),
      ),
    );
  }

  Widget _guestsInput() {
    return InkWell(
      onTap: _openGuestSelector,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: _borderSoft), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [Icon(Icons.people_outline, color: AppColors.textMuted), const SizedBox(width: 10), Expanded(child: Text(_guestsLabel(), style: const TextStyle(color: AppColors.textMuted, fontSize: 15)))]),
      ),
    );
  }
}

