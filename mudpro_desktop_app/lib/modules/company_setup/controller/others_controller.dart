// lib/modules/company_setup/controller/others_controller.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/others_model.dart';

class OthersController {
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ============ ACTIVITY APIs ============
  
  Future<Map<String, dynamic>> addActivities(List<ActivityItem> activities) async {
    try {
      if (activities.length == 1) {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addActivity}'),
          headers: _headers,
          body: jsonEncode(activities.first.toJson()),
        );

        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Activity added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add activity',
          };
        }
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addBulkActivities}'),
          headers: _headers,
          body: jsonEncode(activities.map((e) => e.toJson()).toList()),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': '${activities.length} activities added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add activities',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<ActivityItem>> getActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoint.getActivities}'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => ActivityItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load activities');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateActivity(String id, ActivityItem activity) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${ApiEndpoint.updateActivity}/$id'),
        headers: _headers,
        body: jsonEncode(activity.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Activity updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update activity',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteActivity(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiEndpoint.deleteActivity}/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Activity deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete activity',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============ ADDITION APIs ============
  
  Future<Map<String, dynamic>> addAdditions(List<AdditionItem> additions) async {
    try {
      if (additions.length == 1) {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addAddition}'),
          headers: _headers,
          body: jsonEncode(additions.first.toJson()),
        );

        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Addition added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add addition',
          };
        }
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addBulkAdditions}'),
          headers: _headers,
          body: jsonEncode(additions.map((e) => e.toJson()).toList()),
        );

        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': '${additions.length} additions added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add additions',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<AdditionItem>> getAdditions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoint.getAdditions}'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => AdditionItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load additions');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateAddition(String id, AdditionItem addition) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${ApiEndpoint.updateAddition}/$id'),
        headers: _headers,
        body: jsonEncode(addition.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Addition updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update addition',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteAddition(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiEndpoint.deleteAddition}/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Addition deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete addition',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============ LOSS APIs ============
  
  Future<Map<String, dynamic>> addLosses(List<LossItem> losses) async {
    try {
      if (losses.length == 1) {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addLoss}'),
          headers: _headers,
          body: jsonEncode(losses.first.toJson()),
        );

        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Loss added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add loss',
          };
        }
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addBulkLosses}'),
          headers: _headers,
          body: jsonEncode(losses.map((e) => e.toJson()).toList()),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': '${losses.length} losses added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add losses',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<LossItem>> getLosses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoint.getLosses}'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => LossItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load losses');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateLoss(String id, LossItem loss) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${ApiEndpoint.updateLoss}/$id'),
        headers: _headers,
        body: jsonEncode(loss.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Loss updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update loss',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteLoss(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiEndpoint.deleteLoss}/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Loss deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete loss',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============ WATER-BASED APIs ============
  
  Future<Map<String, dynamic>> addWaterBased(List<WaterBasedItem> waterBased) async {
    try {
      if (waterBased.length == 1) {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addWaterBased}'),
          headers: _headers,
          body: jsonEncode(waterBased.first.toJson()),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Water-based item added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add water-based',
          };
        }
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addBulkWaterBased}'),
          headers: _headers,
          body: jsonEncode(waterBased.map((e) => e.toJson()).toList()),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': '${waterBased.length} water-based items added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add water-based',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<WaterBasedItem>> getWaterBased() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoint.getWaterBased}'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => WaterBasedItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load water-based');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateWaterBased(String id, WaterBasedItem waterBased) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${ApiEndpoint.updateWaterBased}/$id'),
        headers: _headers,
        body: jsonEncode(waterBased.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Water-based updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update water-based',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteWaterBased(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiEndpoint.deleteWaterBased}/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Water-based deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete water-based',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============ OIL-BASED APIs ============
  
  Future<Map<String, dynamic>> addOilBased(List<OilBasedItem> oilBased) async {
    try {
      if (oilBased.length == 1) {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addOilBased}'),
          headers: _headers,
          body: jsonEncode(oilBased.first.toJson()),
        );

        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Oil-based item added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add oil-based',
          };
        }
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addBulkOilBased}'),
          headers: _headers,
          body: jsonEncode(oilBased.map((e) => e.toJson()).toList()),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': '${oilBased.length} oil-based items added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add oil-based',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<OilBasedItem>> getOilBased() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoint.getOilBased}'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => OilBasedItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load oil-based');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateOilBased(String id, OilBasedItem oilBased) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${ApiEndpoint.updateOilBased}/$id'),
        headers: _headers,
        body: jsonEncode(oilBased.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Oil-based updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update oil-based',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteOilBased(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiEndpoint.deleteOilBased}/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Oil-based deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete oil-based',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============ SYNTHETIC APIs ============
  
  Future<Map<String, dynamic>> addSynthetic(List<SyntheticItem> synthetic) async {
    try {
      if (synthetic.length == 1) {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addSynthetic}'),
          headers: _headers,
          body: jsonEncode(synthetic.first.toJson()),
        );

        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Synthetic item added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add synthetic',
          };
        }
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addBulkSynthetic}'),
          headers: _headers,
          body: jsonEncode(synthetic.map((e) => e.toJson()).toList()),
        );

        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': '${synthetic.length} synthetic items added successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add synthetic',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<SyntheticItem>> getSynthetic() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoint.getSynthetic}'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => SyntheticItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load synthetic');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateSynthetic(String id, SyntheticItem synthetic) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${ApiEndpoint.updateSynthetic}/$id'),
        headers: _headers,
        body: jsonEncode(synthetic.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Synthetic updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update synthetic',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteSynthetic(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiEndpoint.deleteSynthetic}/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Synthetic deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete synthetic',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}