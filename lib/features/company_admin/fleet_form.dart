import "package:flutter/material.dart";
import "../../core/api/data_api.dart";
import "../../core/models/models.dart";
import "../../shared/theme/gonyeti_theme.dart";
import "../../shared/widgets/widgets.dart";

class FleetForm extends StatefulWidget {
  const FleetForm({super.key, this.initial});
  final GambitFleet? initial;

  static Future<bool?> show(BuildContext context, {GambitFleet? initial}) {
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
          child: FleetForm(initial: initial),
        ),
      ),
    );
  }

  @override
  State<FleetForm> createState() => _FleetFormState();
}

class _FleetFormState extends State<FleetForm> {
  late final TextEditingController _regCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _regCtrl = TextEditingController(text: widget.initial?.registration);
    _typeCtrl = TextEditingController(text: widget.initial?.vehicleType);
    _makeCtrl = TextEditingController(text: widget.initial?.make);
    _modelCtrl = TextEditingController(text: widget.initial?.model);
    _yearCtrl = TextEditingController(text: widget.initial?.year?.toString());
  }

  @override
  void dispose() {
    _regCtrl.dispose();
    _typeCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reg = _regCtrl.text.trim();
    final type = _typeCtrl.text.trim();
    if (reg.isEmpty || type.isEmpty) {
      setState(() => _error = "Registration and type are required");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final year = int.tryParse(_yearCtrl.text.trim());
      if (widget.initial == null) {
        await FleetApi.create(
          regNumber: reg,
          vehicleType: type,
          make: _makeCtrl.text.trim(),
          model: _modelCtrl.text.trim(),
          year: year,
        );
      } else {
        await FleetApi.update(
          fleetId: widget.initial!.id,
          regNumber: reg,
          vehicleType: type,
          model: _modelCtrl.text.trim(),
          year: year,
        );
      }
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
                widget.initial == null ? "Add Truck" : "Edit Truck",
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
            label: "REGISTRATION NUMBER",
            controller: _regCtrl,
            hint: "e.g. AB 1234",
            textInputAction: TextInputAction.next,
          ),
          GInput(
            label: "VEHICLE TYPE",
            controller: _typeCtrl,
            hint: "e.g. Horse, Trailer, Rigid",
            textInputAction: TextInputAction.next,
          ),
          Row(
            children: [
              Expanded(
                child: GInput(
                  label: "MAKE (Optional)",
                  controller: _makeCtrl,
                  hint: "e.g. Volvo",
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GInput(
                  label: "YEAR (Optional)",
                  controller: _yearCtrl,
                  keyboardType: TextInputType.number,
                  hint: "e.g. 2018",
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          GInput(
            label: "MODEL (Optional)",
            controller: _modelCtrl,
            hint: "e.g. FH16",
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          GButton(
            label: "SAVE TRUCK",
            loading: _loading,
            fullWidth: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
