import "package:flutter/material.dart";
import "../../core/api/data_api.dart";
import "../../core/models/models.dart";
import "../../shared/theme/gonyeti_theme.dart";
import "../../shared/widgets/widgets.dart";

class TripForm extends StatefulWidget {
  const TripForm({required this.fleet, required this.drivers, super.key});
  final List<GambitFleet> fleet;
  final List<GambitDriver> drivers;

  static Future<bool?> show(
    BuildContext context,
    List<GambitFleet> fleet,
    List<GambitDriver> drivers,
  ) {
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
            color: GonyetiColors.elevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: TripForm(fleet: fleet, drivers: drivers),
        ),
      ),
    );
  }

  @override
  State<TripForm> createState() => _TripFormState();
}

class _TripFormState extends State<TripForm> {
  final _refCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _cargoTypeCtrl = TextEditingController();
  final _tonnageCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  String? _selectedHorseId;
  String? _selectedDriverId;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _refCtrl.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    _cargoTypeCtrl.dispose();
    _tonnageCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ref = _refCtrl.text.trim();
    final origin = _originCtrl.text.trim();
    final dest = _destCtrl.text.trim();

    if (ref.isEmpty || origin.isEmpty || dest.isEmpty) {
      setState(
        () => _error = "Reference, Origin, and Destination are required",
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await TripsApi.create(
        reference: ref,
        origin: origin,
        destination: dest,
        cargoType: _cargoTypeCtrl.text.trim(),
        tonnage: double.tryParse(_tonnageCtrl.text.trim()),
        freightRate: double.tryParse(_rateCtrl.text.trim()),
        horseId: _selectedHorseId,
        driverId: _selectedDriverId,
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Create Trip",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: GonyetiColors.text,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: GonyetiColors.textMuted,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null) GAlert(message: _error!, type: "danger"),
          GInput(
            label: "REFERENCE NUMBER",
            controller: _refCtrl,
            hint: "e.g. TRP-1002",
            textInputAction: TextInputAction.next,
          ),
          Row(
            children: [
              Expanded(
                child: GInput(
                  label: "ORIGIN",
                  controller: _originCtrl,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GInput(
                  label: "DESTINATION",
                  controller: _destCtrl,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),

          // Custom Dropdowns for Fleet/Driver
          const Text(
            "ASSIGN HORSE",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: GonyetiColors.textSub,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: GonyetiColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GonyetiColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedHorseId,
                isExpanded: true,
                dropdownColor: GonyetiColors.card,
                items: [
                  const DropdownMenuItem(
                    child: Text(
                      "Unassigned",
                      style: TextStyle(color: GonyetiColors.textMuted),
                    ),
                  ),
                  ...widget.fleet.map(
                    (f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(
                        f.displayName,
                        style: const TextStyle(color: GonyetiColors.text),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedHorseId = v),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            "ASSIGN DRIVER",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: GonyetiColors.textSub,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: GonyetiColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GonyetiColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDriverId,
                isExpanded: true,
                dropdownColor: GonyetiColors.card,
                items: [
                  const DropdownMenuItem(
                    child: Text(
                      "Unassigned",
                      style: TextStyle(color: GonyetiColors.textMuted),
                    ),
                  ),
                  ...widget.drivers.map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: Text(
                        d.fullName,
                        style: const TextStyle(color: GonyetiColors.text),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedDriverId = v),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: GInput(
                  label: "CARGO TYPE",
                  controller: _cargoTypeCtrl,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GInput(
                  label: "TONNAGE",
                  controller: _tonnageCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          GInput(
            label: "FREIGHT RATE",
            controller: _rateCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          GButton(
            label: "CREATE TRIP",
            loading: _loading,
            fullWidth: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
