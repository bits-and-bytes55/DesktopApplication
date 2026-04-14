import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  static const int rows = 20;

  List<TextEditingController> _gen() =>
      List.generate(rows, (_) => TextEditingController());

  // Left
  final checklist = List.generate(rows, (_) => TextEditingController());
  final ppe = List.generate(rows, (_) => TextEditingController());
  final position = List.generate(rows, (_) => TextEditingController());

  // Middle
  final reaction = List.generate(rows, (_) => TextEditingController());
  final tools = List.generate(rows, (_) => TextEditingController());
  final procedures = List.generate(rows, (_) => TextEditingController());

  // Right
  final ruleTitle = TextEditingController(text: 'Safety Rules');
  final ruleBody = TextEditingController();

  final bbsTitle = TextEditingController(text: 'Six Steps for BBS');
  final bbsBody = TextEditingController();

  final obsTitle = TextEditingController(text: 'Observation');
  final obsBody = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            
            if (availableWidth < 1000) {
              return _mobileLayout();
            } else if (availableWidth < 1400) {
              return _mediumLayout();
            } else {
              return _desktopLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _mobileLayout() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _twoColTable('Safety Checklist', checklist),
                const SizedBox(height: 12),
                _twoColTable('Personal Protective Equipment', ppe),
                const SizedBox(height: 12),
                _twoColTable('Position of People', position),
                const SizedBox(height: 12),
                _twoColTable('Reaction of People', reaction),
                const SizedBox(height: 12),
                _twoColTable('Tools & Equipment', tools),
                const SizedBox(height: 12),
                _twoColTable('Procedures & Orderliness', procedures),
                const SizedBox(height: 12),
                _textBlock(ruleTitle, ruleBody),
                const SizedBox(height: 12),
                _textBlock(bbsTitle, bbsBody),
                const SizedBox(height: 12),
                _textBlock(obsTitle, obsBody),
              ],
            ),
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _mediumLayout() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _twoColTable('Safety Checklist', checklist)),
                    const SizedBox(height: 8),
                    Expanded(child: _twoColTable('Personal Protective Equipment', ppe)),
                    const SizedBox(height: 8),
                    Expanded(child: _twoColTable('Position of People', position)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _twoColTable('Reaction of People', reaction)),
                    const SizedBox(height: 8),
                    Expanded(child: _twoColTable('Tools & Equipment', tools)),
                    const SizedBox(height: 8),
                    Expanded(child: _twoColTable('Procedures & Orderliness', procedures)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _textBlock(ruleTitle, ruleBody)),
                    const SizedBox(height: 8),
                    Expanded(child: _textBlock(bbsTitle, bbsBody)),
                    const SizedBox(height: 8),
                    Expanded(child: _textBlock(obsTitle, obsBody)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _desktopLayout() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section([
                _twoColTable('Safety Checklist', checklist),
                _twoColTable('Personal Protective Equipment', ppe),
                _twoColTable('Position of People', position),
              ]),
              const SizedBox(width: 12),
              _section([
                _twoColTable('Reaction of People', reaction),
                _twoColTable('Tools & Equipment', tools),
                _twoColTable('Procedures & Orderliness', procedures),
              ]),
              const SizedBox(width: 12),
              _section([
                _textBlock(ruleTitle, ruleBody),
                _textBlock(bbsTitle, bbsBody),
                _textBlock(obsTitle, obsBody),
              ]),
            ],
          ),
        ),
        _footer(),
      ],
    );
  }

  // =====================================================
  // SECTION WRAPPER - IMPROVED
  // =====================================================
  Widget _section(List<Widget> children) {
    return Expanded(
      child: Column(
        children: children
            .asMap()
            .map((index, e) => MapEntry(
                  index,
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: index < children.length - 1 ? 8 : 0),
                      child: e,
                    ),
                  ),
                ))
            .values
            .toList(),
      ),
    );
  }

  // =====================================================
  // 2 COLUMN TABLE - IMPROVED UI
  // =====================================================
  Widget _twoColTable(String title, List<TextEditingController> ctrls) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          _header(title),
          _tableHeader(),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              child: ListView.builder(
                itemCount: rows,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (_, i) {
                  return Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: i % 2 == 0 ? Colors.white : Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.8),
                                      AppTheme.primaryColor,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: TextField(
                                controller: ctrls[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  hintText: 'Enter description...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // RIGHT TEXT BLOCK - IMPROVED UI
  // =====================================================
  Widget _textBlock(TextEditingController title, TextEditingController body) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: TextField(
                controller: title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Enter title...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: body,
                  expands: true,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    hintText: 'Enter details here...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // COMMON WIDGETS - IMPROVED
  // =====================================================
  Widget _header(String text) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              _getHeaderIcon(text),
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getHeaderIcon(String title) {
    if (title.contains('Checklist')) return Icons.checklist_rounded;
    if (title.contains('PPE') || title.contains('Equipment')) return Icons.security_rounded;
    if (title.contains('Position')) return Icons.people_alt_rounded;
    if (title.contains('Reaction')) return Icons.psychology_rounded;
    if (title.contains('Tools')) return Icons.build_rounded;
    if (title.contains('Procedures')) return Icons.description_rounded;
    return Icons.task_rounded;
  }

  Widget _tableHeader() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: const Center(
              child: Text(
                '#',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // FOOTER - IMPROVED
  // =====================================================
  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              _saveData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Save',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveData() {
    // Collect all data from text controllers
    final Map<String, List<String>> data = {
      'Safety Checklist': checklist.map((c) => c.text).toList(),
      'Personal Protective Equipment': ppe.map((c) => c.text).toList(),
      'Position of People': position.map((c) => c.text).toList(),
      'Reaction of People': reaction.map((c) => c.text).toList(),
      'Tools & Equipment': tools.map((c) => c.text).toList(),
      'Procedures & Orderliness': procedures.map((c) => c.text).toList(),
      'Safety Rules': [ruleTitle.text, ruleBody.text],
      'Six Steps for BBS': [bbsTitle.text, bbsBody.text],
      'Observation': [obsTitle.text, obsBody.text],
    };

    // TODO: Implement actual save logic
    print('Saving safety data: $data');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Safety data saved successfully'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}