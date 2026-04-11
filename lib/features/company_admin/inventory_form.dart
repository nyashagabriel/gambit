import "package:flutter/material.dart";
import "../../core/api/data_api.dart";
import "../../shared/theme/gonyeti_theme.dart";
import "../../shared/widgets/widgets.dart";

class InventoryForm extends StatefulWidget {
  const InventoryForm({super.key});
  static Future<bool?> show(BuildContext context) {
    final colors = context.colors;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.elevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const InventoryForm(),
        ),
      ),
    );
  }

  @override
  State<InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<InventoryForm> {
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: "Pcs");
  final _noteCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final cat = _catCtrl.text.trim();
    final unit = _unitCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;

    if (name.isEmpty || cat.isEmpty || unit.isEmpty) {
      setState(() => _error = "Name, category, and unit are required");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await InventoryApi.create(
        name: name,
        category: cat,
        unit: unit,
        quantity: qty,
        note: _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Add Inventory Item",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: colors.text,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: colors.textMuted,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null) GAlert(message: _error!, type: "danger"),
          GInput(
            label: "ITEM NAME",
            controller: _nameCtrl,
            hint: "e.g. Brake Pads",
            textInputAction: TextInputAction.next,
          ),
          Row(
            children: [
              Expanded(
                child: GInput(
                  label: "CATEGORY",
                  controller: _catCtrl,
                  hint: "e.g. Spares",
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GInput(
                  label: "UNIT",
                  controller: _unitCtrl,
                  hint: "e.g. Pcs, Litres",
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          GInput(
            label: "INITIAL QUANTITY",
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          GInput(
            label: "VENDOR / NOTE",
            controller: _noteCtrl,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          GButton(
            label: "SAVE ITEM",
            loading: _loading,
            fullWidth: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
