import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/tabs/concentration_current_table.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/tabs/concentration_graph.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/tabs/concentration_table_history.dart';

class ConcentrationPage extends StatefulWidget {
  const ConcentrationPage({super.key});

  @override
  State<ConcentrationPage> createState() => _ConcentrationPageState();
}

class _ConcentrationPageState extends State<ConcentrationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedSystem = 'Active System';

  final systems = [
    'Active System',
    'Sand Trap',
    'Desander 1A',
    'Desilter 1B',
    'Intermediate 2A',
    'Intermediate 2B',
    'Intermediate 2C',
    'Suction 4A',
    'Suction 4B',
    'Reserve 5A',
    'Reserve 5B',
    'Reserve 6A',
    'Reserve 6B',
    'Pill 3A',
    'Pill 3B',
    'Slug 3C',
    'Trip Tank',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAF9F6),
      body: Column(
        children: [
          // ================= TOP BAR =================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Concentration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff2D3748),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xffF8F9FA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Color(0xffE2E8F0), width: 1),
                  ),
                  child: DropdownButton<String>(
                    value: selectedSystem,
                    underline: SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: Color(0xff6C9BCF)),
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xff2D3748),
                      fontWeight: FontWeight.w500,
                    ),
                    items: systems
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: TextStyle(color: Color(0xff2D3748)),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedSystem = v!),
                  ),
                ),
              ],
            ),
          ),

          // ================= TABS =================
          Container(
            height: 50, // Decreased height from default
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xffE2E8F0), width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Color(0xff6C9BCF),
              unselectedLabelColor: Color(0xff718096),
              indicatorColor: Color(0xff6C9BCF),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.show_chart, size: 16), // Slightly smaller icon
                  text: 'Graph View',
                ),
                Tab(
                  icon: Icon(Icons.table_chart, size: 16), // Slightly smaller icon
                  text: 'Current Table',
                ),
                Tab(
                  icon: Icon(Icons.history, size: 16), // Slightly smaller icon
                  text: 'History Table',
                ),
              ],
            ),
          ),

          // ================= CONTENT =================
          Expanded(
            child: Container(
              color: Color(0xffF8F9FA),
              child: TabBarView(
                controller: _tabController,
                children: [
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