import "package:flutter/material.dart";
import "../../core/api/data_api.dart";
import "../../core/models/models.dart";
import "../../shared/theme/gambit_theme.dart";
import "../../shared/widgets/widgets.dart";

class DriverForm extends StatefulWidget {
  const DriverForm({super.key, this.initial});
  final GambitDriver? initial;

  static Future<bool?> show(BuildContext context, {GambitDriver? initial}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: GambitColors.elevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DriverForm(initial: initial),
        ),
      ),
    );
  }

  @override
  State<DriverForm> createState() => _DriverFormState();
}

class _DriverFormState extends State<DriverForm> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _licenseCtrl;
  late final TextEditingController _phoneCtrl;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final parts = widget.initial?.fullName.split(' ') ?? [];
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _firstCtrl = TextEditingController(text: first);
    _lastCtrl = TextEditingController(text: last);
    _licenseCtrl = TextEditingController(text: widget.initial?.licenseNumber);
    _phoneCtrl = TextEditingController(text: widget.initial?.phone);
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _licenseCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final license = _licenseCtrl.text.trim();

    if (first.isEmpty || last.isEmpty || license.isEmpty) {
      setState(
        () => _error = "First name, last name, and license are required",
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.initial == null) {
        await DriversApi.create(
          firstName: first,
          lastName: last,
          licenseNumber: license,
          phone: _phoneCtrl.text.trim(),
        );
      } else {
        await DriversApi.update(
          driverId: widget.initial!.id,
          firstName: first,
          lastName: last,
          licenseNumber: license,
          phone: _phoneCtrl.text.trim(),
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
                widget.initial == null ? "Add Driver" : "Edit Driver",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: GambitColors.text,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: GambitColors.textMuted,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null) GAlert(message: _error!, type: "danger"),
          Row(
            children: [
              Expanded(
                child: GInput(
                  label: "FIRST NAME",
                  controller: _firstCtrl,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GInput(
                  label: "LAST NAME",
                  controller: _lastCtrl,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          GInput(
            label: "LICENSE NUMBER",
            controller: _licenseCtrl,
            textInputAction: TextInputAction.next,
          ),
          GInput(
            label: "PHONE NUMBER",
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          GButton(
            label: "SAVE DRIVER",
            loading: _loading,
            fullWidth: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
