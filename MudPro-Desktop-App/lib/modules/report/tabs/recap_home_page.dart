import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_body.dart';

const Color _recapPage = Color(0xFFF4F6FA);
const Color _recapSection = Color(0xFF6C9BCF);

class RecapHomePage extends StatefulWidget {
  const RecapHomePage({super.key});

  @override
  State<RecapHomePage> createState() => _RecapHomePageState();
}

class _RecapHomePageState extends State<RecapHomePage> {
  bool _isSidebarVisible = true;

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: _recapPage,
        appBar: AppBar(
          backgroundColor: _recapSection,
          elevation: 0,
          leading: IconButton(
            icon: Icon(_isSidebarVisible ? Icons.menu_open : Icons.menu),
            onPressed: _toggleSidebar,
          ),
          title: const Text(
            'Recap',
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: RecapBody(
                isSidebarVisible: _isSidebarVisible,
                onToggleSidebar: _toggleSidebar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
