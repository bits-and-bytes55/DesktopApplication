import 'package:flutter/material.dart';
import 'time_distribution_graph.dart';
import 'time_distribution_table.dart';

class TimeDistributionPage extends StatefulWidget {
  const TimeDistributionPage({super.key});

  @override
  State<TimeDistributionPage> createState() => _TimeDistributionPageState();
}

class _TimeDistributionPageState extends State<TimeDistributionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header with Tabs on left
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Title
                Text(
                  'Time Distribution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),

                // Compact Tabs
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TabBar(
                    controller: _tab,
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade700,
                    indicator: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    tabs: const [
                      Tab(text: 'Graph'),
                      Tab(text: 'Table'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: Container(
              color: Colors.white,
              child: TabBarView(
                controller: _tab,
                children:  [
                  TimeDistributionGraph(),
                  TimeDistributionTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}