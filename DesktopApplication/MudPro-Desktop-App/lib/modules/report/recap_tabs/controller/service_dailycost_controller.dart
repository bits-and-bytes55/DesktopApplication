// Controller for managing table data
import 'package:get/get.dart';

class ServiceRecapController extends GetxController {
  final RxList<ServiceEntry> entries = <ServiceEntry>[
    ServiceEntry(date: '12/25/2025', rpt: 1, md: 7700.0),
    ServiceEntry(date: '12/26/2025', rpt: 2, md: 7700.0),
    ServiceEntry(date: '12/27/2025', rpt: 3, md: 7700.0),
    ServiceEntry(date: '12/28/2025', rpt: 4, md: 7700.0),
    ServiceEntry(date: '12/29/2025', rpt: 5, md: 7700.0),
    ServiceEntry(date: '12/30/2025', rpt: 6, md: 7700.0),
    ServiceEntry(date: '12/31/2025', rpt: 7, md: 7700.0),
    ServiceEntry(date: '1/1/2026', rpt: 8, md: 7704.0),
    ServiceEntry(date: '1/2/2026', rpt: 9, md: 7706.0),
    ServiceEntry(date: '1/3/2026', rpt: 10, md: 7715.0),
    ServiceEntry(date: '1/4/2026', rpt: 11, md: 7791.0),
    ServiceEntry(date: '1/5/2026', rpt: 12, md: 7945.0),
    ServiceEntry(date: '1/6/2026', rpt: 13, md: 8833.0),
    ServiceEntry(date: '1/7/2026', rpt: 14, md: 9021.0),
    ServiceEntry(date: '1/8/2026', rpt: 15, md: 9021.0),
  ].obs;

  double get totalMd {
    return entries.fold(0.0, (sum, entry) => sum + entry.md);
  }

  void updateEntry(int index, String field, String value) {
    if (field == 'date') {
      entries[index].date = value;
    } else if (field == 'rpt') {
      entries[index].rpt = int.tryParse(value) ?? entries[index].rpt;
    } else if (field == 'md') {
      entries[index].md = double.tryParse(value) ?? entries[index].md;
    }
    entries.refresh();
  }

  void addEntry() {
    entries.add(ServiceEntry(
      date: '',
      rpt: entries.length + 1,
      md: 0.0,
    ));
  }

  void removeEntry(int index) {
    entries.removeAt(index);
  }
}

class ServiceEntry {
  String date;
  int rpt;
  double md;

  ServiceEntry({
    required this.date,
    required this.rpt,
    required this.md,
  });
}
