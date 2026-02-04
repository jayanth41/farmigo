import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

typedef SearchCallback = void Function(Map<String, dynamic> criteria);

class SearchCard extends StatefulWidget {
  final SearchCallback? onFind;
  const SearchCard({super.key, this.onFind});

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocus = FocusNode();
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;
  String? _activeField;

  @override
  void initState() {
    super.initState();
    _locationFocus.addListener(() {
      setState(() {
        _activeField = _locationFocus.hasFocus ? 'location' : null;
      });
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    setState(() => _activeField = isStart ? 'checkin' : 'checkout');
    final now = DateTime.now();
    final first = isStart ? now : (_checkIn ?? now);
    final picked = await showDatePicker(context: context, initialDate: first, firstDate: now, lastDate: DateTime(now.year + 2));
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
    setState(() => _activeField = null);
  }

  void _openGuestSelector() {
    setState(() => _activeField = 'guests');
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (c, setS) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Adults', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Row(children: [
                    IconButton(onPressed: () => setS(() => _adults = (_adults - 1).clamp(1, 20)), icon: const Icon(Icons.remove_circle_outline)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text('$_adults')),
                    IconButton(onPressed: () => setS(() => _adults = (_adults + 1).clamp(1, 20)), icon: const Icon(Icons.add_circle_outline)),
                  ])
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Children', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Row(children: [
                    IconButton(onPressed: () => setS(() => _children = (_children - 1).clamp(0, 10)), icon: const Icon(Icons.remove_circle_outline)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text('$_children')),
                    IconButton(onPressed: () => setS(() => _children = (_children + 1).clamp(0, 10)), icon: const Icon(Icons.add_circle_outline)),
                  ])
                ]),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done'))),
              ]),
            );
          });
        }).whenComplete(() => setState(() => _activeField = null));
  }

  String _guestsLabel() => '$_adults Adults${_children > 0 ? ', $_children Children' : ''}';

  @override
  Widget build(BuildContext context) {
    final labelStyle =  TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(26),
  boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 22, offset: Offset(0, 12))],
  ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('Location', style: labelStyle)),
        _locationField(),
        const SizedBox(height: 18),

        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('Check-in', style: labelStyle)),
        _dateField(isStart: true, placeholder: 'Select date'),
        const SizedBox(height: 18),

        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('Check-out', style: labelStyle)),
        _dateField(isStart: false, placeholder: 'Select date'),
        const SizedBox(height: 18),

        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('Guests', style: labelStyle)),
        _guestsField(),
        const SizedBox(height: 26),

        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton.icon(
            onPressed: () {
              final criteria = {
                'location': _locationController.text,
                'checkIn': _checkIn?.toIso8601String(),
                'checkOut': _checkOut?.toIso8601String(),
                'adults': _adults,
                'children': _children,
              };
              if (widget.onFind != null) widget.onFind!(criteria);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
            icon: const Icon(Icons.search, color: Colors.white, size: 22),
            label: const Text('Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        )
      ]),
    );
  }

  Widget _locationField() {
    final active = _activeField == 'location';
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(border: Border.all(color: active ? AppColors.primary : AppColors.border(context)), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.location_on_outlined, color: AppColors.iconGrey, size: 22),
        const SizedBox(width: 10),
        Expanded(
            child: TextFormField(
          controller: _locationController,
          focusNode: _locationFocus,
          style: TextStyle(color: AppColors.textMuted(context), fontSize: active ? 16 : 15),
          decoration: InputDecoration(border: InputBorder.none, hintText: 'Search destination, farmhouse', hintStyle: TextStyle(color: AppColors.textMuted(context), fontSize: 15)),
        ))
      ]),
    );
  }

  Widget _dateField({required bool isStart, required String placeholder}) {
    final key = isStart ? 'checkin' : 'checkout';
    final active = _activeField == key;
    final dateText = isStart ? (_checkIn != null ? '${_checkIn!.day}/${_checkIn!.month}/${_checkIn!.year}' : placeholder) : (_checkOut != null ? '${_checkOut!.day}/${_checkOut!.month}/${_checkOut!.year}' : placeholder);
    return InkWell(
      onTap: () => _pickDate(context, isStart),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(border: Border.all(color: active ? AppColors.primary : AppColors.border(context)), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [const Icon(Icons.calendar_today_outlined, color: AppColors.iconGrey, size: 22), const SizedBox(width: 10), Expanded(child: Text(dateText, style: TextStyle(color: AppColors.textMuted(context), fontSize: active ? 16 : 15)))]),
      ),
    );
  }

  Widget _guestsField() {
    final active = _activeField == 'guests';
    return InkWell(
      onTap: _openGuestSelector,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(border: Border.all(color: active ? AppColors.primary : AppColors.border(context)), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [const Icon(Icons.people_outline, color: AppColors.iconGrey, size: 22), const SizedBox(width: 10), Expanded(child: Text(_guestsLabel(), style: TextStyle(color: AppColors.textMuted(context), fontSize: active ? 16 : 15)))]),
      ),
    );
  }
}
