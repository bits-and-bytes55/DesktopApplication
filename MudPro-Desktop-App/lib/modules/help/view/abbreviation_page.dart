import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AbbreviationPage extends StatelessWidget {
  const AbbreviationPage({super.key});

  static const List<_AbbreviationEntry> _entries = [
    _AbbreviationEntry('Ann.', 'Annular'),
    _AbbreviationEntry('Azi', 'Azimuth'),
    _AbbreviationEntry('BHCT', 'Bottom hole circulating temperature'),
    _AbbreviationEntry('BOL', 'Bill of lading'),
    _AbbreviationEntry('Btm', 'Bottom'),
    _AbbreviationEntry('CEC', 'Cation exchange capacity'),
    _AbbreviationEntry('Circ.', 'Circulation'),
    _AbbreviationEntry('Conc.', 'Concentration'),
    _AbbreviationEntry('Crit.', 'Critical'),
    _AbbreviationEntry('Cum.', 'Cumulative'),
    _AbbreviationEntry('Cur.', 'Current'),
    _AbbreviationEntry('Displ.', 'Displacement'),
    _AbbreviationEntry('DS', 'Drilling solids'),
    _AbbreviationEntry('ECD', 'Equivalent circulating density'),
    _AbbreviationEntry('Eff.', 'Efficiency'),
    _AbbreviationEntry('Equip.', 'Equipment'),
    _AbbreviationEntry('Equiv.', 'Equivalent'),
    _AbbreviationEntry('ES', 'Electrical stability'),
    _AbbreviationEntry('ESD', 'Equivalent static density'),
    _AbbreviationEntry('F.', 'Force'),
    _AbbreviationEntry('HGS', 'High gravity solids'),
    _AbbreviationEntry('HHP', 'Hydraulic horsepower'),
    _AbbreviationEntry('HP', 'Horsepower'),
    _AbbreviationEntry('HSI', 'Horsepower per square inch'),
    _AbbreviationEntry('HTHP', 'High temperature high pressure'),
    _AbbreviationEntry('Inc', 'Inclination'),
    _AbbreviationEntry('KOP', 'Kickoff Point'),
    _AbbreviationEntry('LCM', 'Loss circulation material'),
    _AbbreviationEntry('Len.', 'Length'),
    _AbbreviationEntry('LGS', 'Low gravity solids'),
    _AbbreviationEntry('LP', 'Landing point'),
    _AbbreviationEntry('MBT', 'Methylene blue test'),
    _AbbreviationEntry('Mfr.', 'Manufacturer'),
    _AbbreviationEntry('ML', 'Mud line'),
    _AbbreviationEntry('OOC', 'Oil content cuttings'),
    _AbbreviationEntry('O/F', 'Overflow'),
    _AbbreviationEntry('P.', 'Pressure'),
    _AbbreviationEntry('P/U', 'Pull up'),
    _AbbreviationEntry('Nre', 'Reynold number'),
    _AbbreviationEntry('Rec.', 'Received'),
    _AbbreviationEntry('Ret.', 'Returned'),
    _AbbreviationEntry('ROC', 'Retention on cuttings'),
    _AbbreviationEntry('Rot.', 'Rotation'),
    _AbbreviationEntry('RPM', 'Revolutions per minute'),
    _AbbreviationEntry('S/L', 'Sub lease'),
    _AbbreviationEntry('SO', 'Slack off'),
    _AbbreviationEntry('SCE', 'Solid control equipment'),
    _AbbreviationEntry('SG', 'Specific gravity'),
    _AbbreviationEntry('Stk.', 'Stroke'),
    _AbbreviationEntry('Str.', 'Strength'),
    _AbbreviationEntry('Surf.', 'Surface'),
    _AbbreviationEntry('T.', 'Temperature'),
    _AbbreviationEntry('TFA', 'Total flow area'),
    _AbbreviationEntry('U/F', 'Underflow'),
    _AbbreviationEntry('Vel.', 'Velocity'),
    _AbbreviationEntry('Visc.', 'Viscosity'),
    _AbbreviationEntry('Vol.', 'Volume'),
    _AbbreviationEntry('Vsec', 'Vertical section'),
    _AbbreviationEntry('WA', 'Water activity'),
    _AbbreviationEntry('WOB', 'Weight on bit'),
    _AbbreviationEntry('WPS', 'Water phase salinity'),
    _AbbreviationEntry('Wt.', 'Weight'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardColor,
      alignment: Alignment.center,
      child: Container(
        width: 620,
        height: 500,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border.all(color: AppTheme.tableBorderBlue),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _titleBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: _table(),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _titleBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: AppTheme.panelHeaderBlue,
      ),
      child: Row(
        children: [
          Text(
            'Abbreviation',
            style: AppTheme.titleMedium.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _close,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.close, size: 24, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _table() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: Column(
        children: [
          _headerRow(),
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  return _entryRow(_entries[index], index == 0);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      children: [
        _cell(
          'Abbreviation',
          width: 150,
          height: 34,
          color: AppTheme.readOnlyCell,
          center: true,
          isHeader: true,
        ),
        Expanded(
          child: _cell(
            'Explanation',
            height: 34,
            color: AppTheme.readOnlyCell,
            center: true,
            isHeader: true,
          ),
        ),
      ],
    );
  }

  Widget _entryRow(_AbbreviationEntry entry, bool selected) {
    return Row(
      children: [
        _cell(
          entry.abbreviation,
          width: 150,
          height: 30,
          color: selected ? Colors.blue.shade700 : AppTheme.calculatedCell,
          textColor: selected ? Colors.white : AppTheme.textPrimary,
        ),
        Expanded(
          child: _cell(
            entry.explanation,
            height: 30,
            color: AppTheme.calculatedCell,
          ),
        ),
      ],
    );
  }

  Widget _cell(
    String text, {
    double? width,
    required double height,
    required Color color,
    Color textColor = AppTheme.textPrimary,
    bool center = false,
    bool isHeader = false,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: center ? Alignment.center : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: center ? 4 : 6),
      decoration: BoxDecoration(
        color: color,
        border: Border(
          right: BorderSide(color: Colors.grey.shade600),
          bottom: BorderSide(color: Colors.grey.shade600),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 15,
          color: textColor,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      height: 56,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      child: SizedBox(
        width: 118,
        height: 38,
        child: OutlinedButton(
          onPressed: _close,
          child: Text(
            'Close',
            style: AppTheme.bodyLarge.copyWith(fontSize: 15),
          ),
        ),
      ),
    );
  }

  void _close() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().closeOverlay();
    }
  }
}

class _AbbreviationEntry {
  const _AbbreviationEntry(this.abbreviation, this.explanation);

  final String abbreviation;
  final String explanation;
}
