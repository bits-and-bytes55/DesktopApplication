import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/UG_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PitView extends StatelessWidget {
  PitView({super.key});

  final c = Get.find<UgController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width / 2, // 页面一半宽度
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            children: [
              _header(),
              _tableHeader(),
              Expanded(child: _tableBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_damage, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Text(
            "Pit Configuration",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          const Text(
            "Total Capacity: ",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${c.totalCapacity.value} bbl",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ================= TABLE HEADER =================
  Widget _tableHeader() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          _headerCell("Pit/Tank", 200),
          _headerCell("Capacity (BBL)", 150),
          _headerCell("Initial Active", 120),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  // ================= TABLE BODY =================
  Widget _tableBody() {
    return Obx(() {
      if (c.pits.isEmpty) {
        return const Center(
          child: Text(
            "No pits available",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      return ListView.separated(
        itemCount: c.pits.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade100,
        ),
        itemBuilder: (context, index) {
          final pit = c.pits[index];
          return _pitRow(pit, index);
        },
      );
    });
  }

  Widget _pitRow(dynamic pit, int index) {
    return Container(
      height: 40,
      color: index.isEven ? Colors.white : Colors.grey.shade50,
      child: Row(
        children: [
          // Pit/Tank Name Column
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Text(
              pit.pit ?? pit.name ?? "Unknown",
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Capacity Column
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Obx(() => c.isLocked.value
                ? Text(
                    "${pit.capacity ?? "0"} bbl",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  )
                : Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextFormField(
                      initialValue: pit.capacity?.toString() ?? "0",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        suffixText: 'bbl',
                        suffixStyle: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        pit.capacity = value;
                        c.updateTotalCapacity();
                      },
                    ),
                  )),
          ),

          // Initial Active Column (Checkbox)
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Obx(() {
              final isActive = pit.active.value;
              return Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: isActive 
                      ? AppTheme.successColor.withOpacity(0.1) 
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isActive 
                        ? AppTheme.successColor 
                        : Colors.grey.shade400,
                  ),
                ),
                child: Checkbox(
                  value: isActive,
                  onChanged: c.isLocked.value
                      ? null
                      : (value) {
                          pit.active.value = value ?? false;
                        },
                  activeColor: AppTheme.successColor,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}