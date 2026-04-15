// ======================== FILE 1: daily_total_cost_page.dart ========================

import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/total_cost/graph_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/total_cost/table_tab.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/depth_cost/tabs/depth_cost_graph.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/depth_cost/tabs/depth_cost_product_tab.dart';

class DepthCostTabView extends StatefulWidget {
  const DepthCostTabView({super.key});

  @override
  State<DepthCostTabView> createState() => _DepthCostTabViewState();
}

class _DepthCostTabViewState extends State<DepthCostTabView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xffFAF9F6),
            Color(0xffF0F5FF),
          ],
        ),
      ),
      child: Column(
        children: [
          // Custom styled TabBar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    icon: Icon(Icons.table_chart, size: 18),
                    text: 'Table View',
                  ),
                  Tab(
                    icon: Icon(Icons.bar_chart, size: 18),
                    text: 'Graph View',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  const DepthCostProductTable(),
                  const DepthCostGraphTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

