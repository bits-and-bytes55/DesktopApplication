import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/company_setup/tabs/mud_company_page.dart';
import 'package:mudpro_desktop_app/modules/company_setup/tabs/operatos_tab.dart';
import 'package:mudpro_desktop_app/modules/company_setup/tabs/others_page.dart';
import 'package:mudpro_desktop_app/modules/company_setup/tabs/products_page.dart';
import 'package:mudpro_desktop_app/modules/company_setup/tabs/safety_page.dart';
import 'package:mudpro_desktop_app/modules/company_setup/tabs/service_page.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

/// =======================================================
/// COMPANY SETUP PAGE (ALL TABS IN ONE FILE)
/// =======================================================
class CompanySetupPage extends StatefulWidget {
  const CompanySetupPage({super.key});

  @override
  State<CompanySetupPage> createState() => _CompanySetupPageState();
}

class _CompanySetupPageState extends State<CompanySetupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLocked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _topBar(),
          _tabBar(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.backgroundColor,
                    AppTheme.cardColor,
                  ],
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: const [
                MudCompanyPage(),
                  ProductPage(),
                  ServicesPage(),
                  OperatorTab(),
                  OthersPage(),
                  SafetyPage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ===================================================
  /// TOP BAR
  /// ===================================================
  Widget _topBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              Icons.business,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'MUDPRO+ - Company Setup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isLocked ? 'Locked' : 'Editable',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {},
            style: AppTheme.secondaryButtonStyle.copyWith(
              backgroundColor: MaterialStateProperty.all(Colors.white.withOpacity(0.9)),
              foregroundColor: MaterialStateProperty.all(AppTheme.primaryColor),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            icon: Icon(
              Icons.file_upload,
              color: AppTheme.primaryColor,
              size: 18,
            ),
            label: Text(
              'Import',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {},
            style: AppTheme.primaryButtonStyle.copyWith(
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            icon: const Icon(Icons.file_download, size: 18),
            label: const Text(
              'Export',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// ===================================================
  /// TAB BAR
  /// ===================================================
  Widget _tabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Engineers'),
          Tab(text: 'Product'),
          Tab(text: 'Services'),
          Tab(text: 'Operator'),
          Tab(text: 'Others'),
          Tab(text: 'Safety'),
        ],
      ),
    );
  }
}

