import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_concentration_controller.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/tabs/concentration_current_table.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/tabs/concentration_graph.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/tabs/concentration_table_history.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ConcentrationPage extends StatefulWidget {
  const ConcentrationPage({super.key});

  @override
  State<ConcentrationPage> createState() => _ConcentrationPageState();
}

class _ConcentrationPageState extends State<ConcentrationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ReportConcentrationController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = Get.isRegistered<ReportConcentrationController>()
        ? Get.find<ReportConcentrationController>()
        : Get.put(ReportConcentrationController());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Obx(() {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Concentration',
                          style: AppTheme.titleMedium.copyWith(
                            fontSize: 20,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _controller.summaryText,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xffE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _controller.selectedSystem.value,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppTheme.primaryColor,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        items: _controller.systems
                            .map(
                              (system) => DropdownMenuItem<String>(
                                value: system,
                                child: Text(system),
                              ),
                            )
                            .toList(),
                        onChanged: _controller.updateSelectedSystem,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _controller.refreshData,
                    tooltip: 'Refresh concentration snapshot',
                    icon: const Icon(
                      Icons.refresh,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              );
            }),
          ),
          Container(
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xffE2E8F0), width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.show_chart, size: 16), text: 'Graph View'),
                Tab(
                  icon: Icon(Icons.table_chart, size: 16),
                  text: 'Current Table',
                ),
                Tab(icon: Icon(Icons.history, size: 16), text: 'History Table'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ConcentrationGraphTab(),
                  ConcentrationCurrentTable(),
                  ConcentrationTableHistory(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
