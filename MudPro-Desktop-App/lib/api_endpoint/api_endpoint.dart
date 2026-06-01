import 'package:mudpro_desktop_app/modules/installation/installation_identity.dart';

class ApiEndpoint {
  static const String baseUrl = "http://213.210.37.129/api/";
  static const String localDevBaseUrl = "http://localhost:3000/api/";
  static const String installationHeader = "X-MudPro-Installation-Id";
  static const String machineHeader = "X-MudPro-Machine-Key";
  static const Map<String, String> noCacheHeaders = {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
  };

  static Iterable<String> get candidateBaseUrls sync* {
    final seen = <String>{};
    final primaryIsLocal =
        baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1');
    final sources = primaryIsLocal ? [baseUrl, localDevBaseUrl] : [baseUrl];

    for (final source in sources) {
      final normalized = source.endsWith('/') ? source : '$source/';
      if (seen.add(normalized)) {
        yield normalized;
      }
    }
  }

  static Map<String, String> get jsonHeaders => withInstallationHeaders({
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  });

  static Map<String, String> withInstallationHeaders(
    Map<String, String> headers,
  ) {
    final id = InstallationIdentity.id.trim();
    final machineKey = InstallationIdentity.machineKey.trim();
    return {
      ...noCacheHeaders,
      ...headers,
      if (id.isNotEmpty) installationHeader: id,
      if (machineKey.isNotEmpty) machineHeader: machineKey,
    };
  }


 static final String addEngineersData = "engineers/add-engineers";
  static final String getEngineersData = "engineers/get-engineers";
  static final String updateEngineer = "engineers/update-engineer";
  static final String deleteEngineer = "engineers/delete-engineer";
  static final String getCompanyDetails = "company/get-company-details";
  static final String addCompanyDetails = "company/add-company-details";
  static final String updateCompanyDetails = "company/update-company-details";

  static final String addPackages = "services/packages/add-package";
  static final String getPackages = "services/packages/get-package";
  static final String addBulkPackages = "services/packages/add-bulk-packages";
  static const String updatePackage = 'services/packages'; // PUT /:id
  static const String deletePackage = 'services/packages'; // DELETE /:id


  static final String addEngineering = "services/engineering/add-engineering";
  static final String getEngineering = "services/engineering/get-engineering";
  static final String addBulkEngineering = "services/engineering/add-bulk-engineering";
   static const String updateEngineering = 'services/engineering'; // PUT /:id
  static const String deleteEngineering = 'services/engineering'; // DELETE /:id

  static final String addServices = "services/add-service";
  static final String getServices = "services/get-service";
  static final String addBulkServices = "services/add-bulk-services";
    static const String updateService = 'services'; // PUT /:id
  static const String deleteService = 'services'; // DELETE /:id

  static final String saveOperators = "operators/add-operators";
  static final String getOperators = "operators/get-operators";
  static const String updateOperator = 'operators'; // PUT /:id
static const String deleteOperator = 'operators'; // DELETE /:id

  static final String addProducts = "v1/products";
  static final String getProducts = "v1/products";
  static final String addBulkProducts = "v1/products/bulk";
  static final String addExcel = "v1/products/excel";


// ============ ACTIVITY ENDPOINTS ============
  static const String addActivity = "activity/add-activity"; // Single
  static const String addBulkActivities = "activity/add-bulk-activities"; // Bulk
  static const String getActivities = "activity/get-activities";
  static const String updateActivity = "activity"; // /:id
  static const String deleteActivity = "activity"; // /:id
  
  // ============ ADDITION ENDPOINTS ============
  static const String addAddition = "addition/add-addition"; // Single
  static const String addBulkAdditions = "addition/add-bulk-additions"; // Bulk
  static const String getAdditions = "addition/get-additions";
  static const String updateAddition = "addition"; // /:id
  static const String deleteAddition = "addition"; // /:id
  
  // ============ LOSS ENDPOINTS ============
  static const String addLoss = "loss/add-loss"; // Single
  static const String addBulkLosses = "loss/add-bulk-losses"; // Bulk
  static const String getLosses = "loss/get-losses";
  static const String updateLoss = "loss"; // /:id
  static const String deleteLoss = "loss"; // /:id

  // ============ WATER-BASED ENDPOINTS ============
  static const String addWaterBased = "waterbased/add-waterbased"; // Single
  static const String addBulkWaterBased = "waterbased/add-bulk-waterbased"; // Bulk
  static const String getWaterBased = "waterbased/get-waterbased";
  static const String updateWaterBased = "waterbased"; // /:id
  static const String deleteWaterBased = "waterbased"; // /:id

  // ============ OIL-BASED ENDPOINTS ============
  static const String addOilBased = "oilbased/add-oilbased"; // Single
  static const String addBulkOilBased = "oilbased/add-bulk-oilbased"; // Bulk
  static const String getOilBased = "oilbased/get-oilbased";
  static const String updateOilBased = "oilbased"; // /:id
  static const String deleteOilBased = "oilbased"; // /:id

  // ============ SYNTHETIC ENDPOINTS ============
  static const String addSynthetic = "synthetic/add-synthetic"; // Single
  static const String addBulkSynthetic = "synthetic/add-bulk-synthetic"; // Bulk
  static const String getSynthetic = "synthetic/get-synthetic";
  static const String updateSynthetic = "synthetic"; // /:id
  static const String deleteSynthetic = "synthetic"; // /:id


  // ============ PREMIXED ENDPOINTS ============
  static const String addPremixed = "inventory/add-premixed"; // POST /:wellId
  static const String getPremixed = "inventory/get-premixed"; // GET /:wellId
  static const String updatePremixed = "inventory/update-premixed"; // PUT /:id
  static const String deletePremixed = "inventory/delete-premixed"; // DELETE /:id

  // ============ OBM ENDPOINTS ============
  static const String getObm = "inventory/get-obm"; // GET /:wellId
  static const String addObm = "inventory/add-obm"; // POST /:wellId
  static const String updateObm = "inventory/update-obm"; // PUT /:id
  static const String deleteObm = "inventory/delete-obm"; // DELETE /:id

  // ============ UNIT SYSTEM ENDPOINTS ============
  static const String unitSystems = "unit-systems";
  static const String seedUnitSystems = "unit-systems/seed";

  // ============ WELL GENERAL ENDPOINTS ============
  static const String wellGeneral = "well-general";

  // ============ NOZZLE ENDPOINTS ============
  static const String nozzle = "nozzle";

}
