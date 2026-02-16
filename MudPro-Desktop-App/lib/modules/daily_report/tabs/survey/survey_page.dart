import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/survey/tabs/survey_3dgraph_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/survey/tabs/survey_actual_table.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/survey/tabs/survey_graph_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/survey/tabs/survey_planned_table.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SurveyPage extends StatelessWidget {
  const SurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // VERY COMPACT TABS (Icons only)
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Tabs as compact buttons
                _TabButton(
                  icon: Icons.bar_chart,
                  label: 'Graph',
                  index: 0,
                ),
                _TabButton(
                  icon: Icons.threed_rotation,
                  label: '3D',
                  index: 1,
                ),
                _TabButton(
                  icon: Icons.table_chart,
                  label: 'Actual',
                  index: 2,
                ),
                _TabButton(
                  icon: Icons.table_rows,
                  label: 'Planned',
                  index: 3,
                ),
              ],
            ),
          ),

          // TAB CONTENT
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.backgroundColor.withOpacity(0.3),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
              child: const TabBarView(
                children: [
                  SurveyChartsPage(),
                  Survey3DChartPage(),
                  SurveyTableActual(),
                  SurveyTablePlanned(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.index,
  });

  @override
  _TabButtonState createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  late TabController _tabController;
  bool _isSelected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabController = DefaultTabController.of(context)!;
    _tabController.addListener(_handleTabChange);
    _updateSelection();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _updateSelection();
    });
  }

  void _updateSelection() {
    _isSelected = _tabController.index == widget.index;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(widget.index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isSelected
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: _isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: _isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: _isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
