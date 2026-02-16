import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AlertSummaryPage extends StatelessWidget {
  const AlertSummaryPage({super.key});

  static const double rowH = 38;

  // ================= COMMON CELL =================
  Widget _cell(
    String text, {
    double w = 100,
    bool bold = false,
    bool isHeader = false,
    bool isSubHeader = false,
    Alignment align = Alignment.center,
    Color? bgColor,
  }) {
    return Container(
      width: w,
      height: rowH,
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isHeader
            ? AppTheme.primaryColor
            : isSubHeader
                ? AppTheme.primaryColor.withOpacity(0.1)
                : bgColor ?? Colors.white,
        border: Border.all(
          color: isHeader ? AppTheme.primaryColor : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: isHeader || isSubHeader ? 11 : 12,
          fontWeight: bold || isHeader || isSubHeader
              ? FontWeight.w600
              : FontWeight.normal,
          color: isHeader
              ? Colors.white
              : isSubHeader
                  ? AppTheme.primaryColor
                  : AppTheme.textPrimary,
        ),
      ),
    );
  }

  // ================= PROGRESS SECTION =================
  Widget _progressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Overview',
                style: AppTheme.titleMedium.copyWith(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Real-time Monitoring',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _progressRow('Depth', 0.65, AppTheme.primaryColor, context),
          const SizedBox(height: 12),
          _progressRow('Day', 0.47, AppTheme.secondaryColor, context),
          const SizedBox(height: 12),
          _progressRow('Cost', 0.38, AppTheme.accentColor, context),
        ],
      ),
    );
  }

  Widget _progressRow(String label, double value, Color color, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * value * 0.8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= KPI TABLE =================
  Widget _kpiTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KPI Performance',
            style: AppTheme.titleMedium.copyWith(
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Main Header Row
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(children: [
              _cell('KPI', w: 120, isHeader: true),
              _cell('Target', w: 90, isHeader: true),
              _cell('Current', w: 180, isHeader: true),
              _cell('Pace', w: 180, isHeader: true),
              _cell('Remaining', w: 120, isHeader: true),
            ]),
          ),
          // Sub Header Row
          Row(children: [
            _cell('', w: 120, isSubHeader: true),
            _cell('', w: 90, isSubHeader: true),
            _cell('Value', w: 90, isSubHeader: true),
            _cell('%', w: 90, isSubHeader: true),
            _cell('Value', w: 90, isSubHeader: true),
            _cell('%', w: 90, isSubHeader: true),
            _cell('', w: 120, isSubHeader: true),
          ]),
          // Data Rows
          _kpiRow('Depth (ft)', '9589.0', '96.0', '1.0', '2.0', '47.1',
              '9493.0', 0),
          _kpiRow('Day', '47', '1', '2.1', '1', '100.0', '46', 1),
          _kpiRow('Cost (€)', '97037.72', '3655.70', '3.8', '77.78', '177.1',
              '93382.02', 2),
        ],
      ),
    );
  }

  Widget _kpiRow(
    String kpi,
    String target,
    String cVal,
    String cPer,
    String pVal,
    String pPer,
    String rem,
    int index,
  ) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
    ];
    final rowColor = colors[index % colors.length];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(children: [
        _cell(kpi,
            w: 120,
            align: Alignment.centerLeft,
            bgColor: rowColor.withOpacity(0.05)),
        _cell(target, w: 90),
        _cell(cVal, w: 90, bold: true, bgColor: Colors.grey.shade50),
        _cell(cPer, w: 90),
        _cell(pVal, w: 90, bold: true, bgColor: Colors.grey.shade50),
        _cell(pPer, w: 90),
        _cell(rem, w: 120, bgColor: Colors.grey.shade50),
      ]),
    );
  }

  // ================= AVERAGE TABLE =================
  Widget _averageTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average Values',
            style: AppTheme.titleMedium.copyWith(
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _averageRow('Avg. ROP', '38.00', AppTheme.primaryColor),
          _averageRow('Avg. Daily Cost', '3655.70', AppTheme.secondaryColor),
          _averageRow('Daily Footage', '96.0', AppTheme.accentColor),
          _averageRow('Current Mud Type', 'Water-based', AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _averageRow(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ALERT TABLE =================
  Widget _alertTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alert Parameters',
                style: AppTheme.titleMedium.copyWith(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 14, color: AppTheme.errorColor),
                    const SizedBox(width: 6),
                    Text(
                      '3 Warnings Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 860,
                child: Column(
                  children: [
                    // Header Row
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(children: [
                        _cell('No', w: 40, isHeader: true),
                        _cell('Parameter', w: 160, isHeader: true),
                        _cell('Unit', w: 80, isHeader: true),
                        _cell('Value', w: 90, isHeader: true),
                        _cell('Range', w: 140, isHeader: true),
                        _cell('Illustration', w: 260, isHeader: true),
                        _cell('Warning', w: 90, isHeader: true),
                      ]),
                    ),
                    // Data Rows
                    _alertRow('1', 'Pump P.', 'psi', '140', 0.65, true),
                    _alertRow('2', 'Pump HHP', 'HP', '245', 0.95, false),
                    _alertRow('3', 'BH ECD', 'ppg', '9.65', 0.75, true),
                    _alertRow('4', 'Viscosity', 'sec/qt', '57', 0.55, true),
                    _alertRow('5', 'YP', 'lb/100ft²', '26', 0.85, false),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertRow(
    String no,
    String param,
    String unit,
    String value,
    double level,
    bool isWarning,
  ) {
    final statusColor = isWarning ? AppTheme.errorColor : AppTheme.successColor;
    final gradientColors = isWarning
        ? [Colors.orange, Colors.red]
        : [Colors.green, Colors.lightGreen];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(children: [
        _cell(no, w: 40, bgColor: Colors.grey.shade50),
        _cell(param, w: 160, align: Alignment.centerLeft),
        _cell(unit, w: 80),
        _cell(value,
            w: 90,
            bold: true,
            bgColor: isWarning
                ? AppTheme.errorColor.withOpacity(0.1)
                : AppTheme.successColor.withOpacity(0.1)),
        _cell('', w: 140),
        Container(
          width: 260,
          height: rowH,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              // Background bar
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              // Progress bar
              Container(
                height: 14,
                width: 230 * level,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              // Value indicator
              Positioned(
                left: 225 * level,
                child: Container(
                  width: 6,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: statusColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Level text
              Positioned(
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${(level * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 90,
          height: rowH,
          alignment: Alignment.center,
          color: statusColor,
          child: Text(
            isWarning ? 'WARNING' : 'NORMAL',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ]),
    );
  }

  // Helper to get context for progress bars
  static BuildContext? getContext() {
    return navigatorKey.currentContext;
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _progressSection(context),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _kpiTable()),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 300,
                    child: _averageTable(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _alertTable(),
              const SizedBox(height: 16),

              // Summary Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Last Updated: Today 14:30',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.secondaryColor.withOpacity(0.1),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Alert Summary Dashboard',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}