import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class EngineeringToolsController extends GetxController {
  final OptionsController _options = AppUnits.controller;

  // Main Engineering Tabs
  var activeMainTab = 0.obs;

  // Hydraulics Sub Tabs
  var activeHydraulicsTab = 0.obs;

  // Pressure Sub Tabs
  var activePressureTab = 0.obs;

  // Mud Weight Sub Tabs
  var activeMudWeightTab = 0.obs;

  // Volume Sub Tabs
  var activeVolumeTab = 0.obs;

  // Pump Out Sub Tabs
  var activePumpOutTab = 0.obs;

  // Oil Mud Sub Tabs
  var activeOilMudTab = 0.obs;

  // Annular Velocity Inputs
  var pumpOutput = ''.obs;
  var holeSize = ''.obs;
  var pipeOD = ''.obs;

  var annularVelocity = RxnDouble();

  // Critical Velocity (Annulus)
  var criticalAnnulusMw = ''.obs;
  var criticalAnnulusPv = ''.obs;
  var criticalAnnulusYp = ''.obs;
  var criticalAnnulusHoleId = ''.obs;
  var criticalAnnulusPipeOd = ''.obs;
  var criticalAnnulusVelocity = RxnDouble();

  // Critical Velocity (Pipe)
  var criticalPipeMw = ''.obs;
  var criticalPipePv = ''.obs;
  var criticalPipeYp = ''.obs;
  var criticalPipeId = ''.obs;
  var criticalPipeVelocity = RxnDouble();

  // ECD
  var ecdMw = ''.obs;
  var ecdYp = ''.obs;
  var ecdHoleSize = ''.obs;
  var ecdPipeOd = ''.obs;
  var ecd = RxnDouble();

  // Pressure Test
  var pressureTestMwInHole = ''.obs;
  var pressureTestWeight = ''.obs;
  var pressureTestDepth = ''.obs;
  var surfaceTestPressure = RxnDouble();

  // Leak-off Test
  var leakOffMwInHole = ''.obs;
  var leakOffSurfacePressure = ''.obs;
  var leakOffTestDepth = ''.obs;
  var fractureGradient = RxnDouble();

  // Max. Allowable SICP
  var sicpMw = ''.obs;
  var sicpFractureGradient = ''.obs;
  var sicpLastCasingDepth = ''.obs;
  var maxAllowableSicp = RxnDouble();

  // Kill Mud Weight
  var killMw = ''.obs;
  var killSidpp = ''.obs;
  var killTvd = ''.obs;
  var killMudWeight = RxnDouble();

  // Overbalance Mud Weight
  var overbalanceMw = ''.obs;
  var overbalanceSidpp = ''.obs;
  var overbalanceTvd = ''.obs;
  var overbalanceMudWeight = RxnDouble();

  // Equivalent Mud Weight
  var equivalentMw = ''.obs;
  var equivalentSicp = ''.obs;
  var equivalentTvd = ''.obs;
  var equivalentMudWeight = RxnDouble();

  // Weight Up (No volume increase)
  var weightUpNoVolumeOriginalMw = ''.obs;
  var weightUpNoVolumeDesiredMw = ''.obs;
  var weightUpNoVolumeBarite = RxnDouble();
  var weightUpNoVolumeJet = RxnDouble();

  // Weight Up (Volume increase)
  var weightUpVolumeOriginalMw = ''.obs;
  var weightUpVolumeDesiredMw = ''.obs;
  var weightUpVolumeBarite = RxnDouble();
  var weightUpVolumeIncrease = RxnDouble();

  // Cut Back (No volume change)
  var cutBackOriginalMw = ''.obs;
  var cutBackDesiredMw = ''.obs;
  var cutBackFluidWeight = ''.obs;
  var cutBackOriginalVolume = ''.obs;
  var cutBackVolumeToJet = RxnDouble();

  // Hole Volume
  var holeVolumeHoleSize = ''.obs;
  var holeVolumeLength = ''.obs;
  var holeVolumePipeDisplacement = ''.obs;
  var holeCapacity = RxnDouble();
  var holeVolume = RxnDouble();

  // Annular Volume
  var annularVolumeHoleSize = ''.obs;
  var annularVolumeLength = ''.obs;
  var annularVolumePipeDisplacement = ''.obs;
  var annularHoleCapacity = RxnDouble();
  var annularVolume = RxnDouble();

  // Capacity
  var capacityPipeId = ''.obs;
  var capacityPipeLength = ''.obs;
  var pipeCapacity = RxnDouble();

  // Displacement
  var displacementPipeWeight = ''.obs;
  var displacementPipeLength = ''.obs;
  var pipeDisplacement = RxnDouble();

  // Rectangular Pits
  var rectangularPitLength = ''.obs;
  var rectangularPitWidth = ''.obs;
  var rectangularPitDepth = ''.obs;
  var rectangularTotalVolume = RxnDouble();
  var rectangularVolumePerInch = RxnDouble();
  var rectangularVolumePerFoot = RxnDouble();

  // Vertical Cylindrical Tank
  var verticalTankDiameter = ''.obs;
  var verticalTankHeight = ''.obs;
  var verticalTankFluidDepth = ''.obs;
  var verticalTankCapacity = RxnDouble();
  var verticalTankFluidVolume = RxnDouble();

  // Horizontal Cylindrical Tank
  var horizontalTankDiameter = ''.obs;
  var horizontalTankLength = ''.obs;
  var horizontalTankFluidDepth = ''.obs;
  var horizontalTankCapacity = RxnDouble();
  var horizontalTankFluidVolume = RxnDouble();

  // Duplex Pump
  var duplexLinerId = ''.obs;
  var duplexRodOd = ''.obs;
  var duplexStrokeLength = ''.obs;
  var duplexEfficiency = ''.obs;
  var duplexPumpOutput = RxnDouble();

  // Triplex Pump
  var triplexLinerId = ''.obs;
  var triplexStrokeLength = ''.obs;
  var triplexEfficiency = ''.obs;
  var triplexPumpOutput = RxnDouble();

  // O/W Ratio
  var owRetortOil = ''.obs;
  var owRetortWater = ''.obs;
  var owOilInLiquidPhase = RxnDouble();
  var owWaterInLiquidPhase = RxnDouble();

  // Ratio Change
  var ratioRetortOil = ''.obs;
  var ratioRetortWater = ''.obs;
  var ratioOilInLiquidPhase = ''.obs;
  var ratioWaterInLiquidPhase = ''.obs;
  var ratioAdd = ''.obs;
  var ratioVolume = RxnDouble();

  // Mixture Density
  var mixtureDieselDensity = ''.obs;
  var mixtureWaterDensity = ''.obs;
  var mixtureOilInLiquidPhase = ''.obs;
  var mixtureWaterInLiquidPhase = ''.obs;
  var mixtureDensity = RxnDouble();

  // Starting Volume
  var startingInitialDensity = ''.obs;
  var startingDesiredDensity = ''.obs;
  var startingBariteDensity = ''.obs;
  var startingDesiredVolume = ''.obs;
  var startingVolume = RxnDouble();

  // Max ROP
  var maxRopHoleId = ''.obs;
  var maxRopPipeOd = ''.obs;
  var maxRopCuttingDiameter = ''.obs;
  var maxRopCuttingDensity = ''.obs;
  var maxRopMw = ''.obs;
  var maxRopPv = ''.obs;
  var maxRopYp = ''.obs;
  var maxRopFlowRate = ''.obs;
  var maxRopCuttingConcentration = ''.obs;
  var maxRop = RxnDouble();

  // Solids Removal Performance
  var solidsBaseFluidVolume = ''.obs;
  var solidsBaseFluidFraction = ''.obs;
  var solidsDrilledSolidsFraction = ''.obs;
  var solidsWellboreLength = ''.obs;
  var solidsWellboreId = ''.obs;
  var solidsMudBuiltVolume = RxnDouble();
  var solidsDrilledVolume = RxnDouble();
  var solidsTotalDilution = RxnDouble();
  var solidsDilutionFactor = RxnDouble();
  var solidsPerformance = RxnDouble();

  // Cost Effectiveness of SCE
  var sceDailyOperatingTime = ''.obs;
  var sceDiscardFlowRate = ''.obs;
  var sceDiscardDensity = ''.obs;
  var sceSolidsVolumePercent = ''.obs;
  var sceBentoniteContent = ''.obs;
  var sceChlorideContent = ''.obs;
  var sceDesiredDrilledSolidsContent = ''.obs;
  var sceDrilledSolidsDensity = ''.obs;
  var sceWeightingMaterialDensity = ''.obs;
  var sceDrillingFluidCost = ''.obs;
  var sceLiquidPhaseCost = ''.obs;
  var sceWeightingMaterialCost = ''.obs;
  var sceChemicalsCost = ''.obs;
  var sceDailyRentalEquipmentCost = ''.obs;
  var sceWasteDisposalCost = ''.obs;
  var sceCorrectedLiquidContent = RxnDouble();
  var sceCorrectedSolidsContent = RxnDouble();
  var sceLiquidPhaseDensity = RxnDouble();
  var sceSolidsDensity = RxnDouble();
  var sceWeightingMaterialContent = RxnDouble();
  var sceWeightingMaterialPercentage = RxnDouble();
  var sceLgsContent = RxnDouble();
  var sceDrilledSolidsPercentage = RxnDouble();
  var sceDrilledSolidsContent = RxnDouble();
  var sceVolumePerDay = RxnDouble();
  var sceLiquidVolume = RxnDouble();
  var sceDrilledSolidsVolume = RxnDouble();
  var sceWeightingMaterialVolume = RxnDouble();
  var sceWeightingMaterialCostPerDay = RxnDouble();
  var sceChemicalsCostPerDay = RxnDouble();
  var sceLiquidCostPerDay = RxnDouble();
  var sceDisposeCostPerDay = RxnDouble();
  var sceTotalCostPerDay = RxnDouble();
  var sceDilutionVolume = RxnDouble();
  var sceDilutionCostPerDay = RxnDouble();
  var sceCostEffectiveness = RxnDouble();
  var sceCostEffectivenessText = ''.obs;

  final List<Worker> _unitWorkers = <Worker>[];
  var _unitSyncScheduled = false;
  late String _annularFlowUnit;
  late String _flowUnit;
  late String _diameterUnit;
  late String _mudWeightUnit;
  late String _viscosityUnit;
  late String _yieldPointUnit;
  late String _lengthUnit;
  late String _pressureUnit;
  late String _volumeUnit;
  late String _volumePerLengthUnit;
  late String _ropUnit;

  @override
  void onInit() {
    super.onInit();
    _annularFlowUnit = AppUnits.cementingFlowRate;
    _flowUnit = AppUnits.drillingFlowRate;
    _diameterUnit = AppUnits.diameter;
    _mudWeightUnit = AppUnits.mudWeight;
    _viscosityUnit = AppUnits.viscosity;
    _yieldPointUnit = AppUnits.yieldPoint;
    _lengthUnit = AppUnits.length;
    _pressureUnit = AppUnits.pressure;
    _volumeUnit = AppUnits.fluidVolume;
    _volumePerLengthUnit = AppUnits.pipeCapacityVolumeLength;
    _ropUnit = AppUnits.rop;
    _unitWorkers.addAll([
      ever(_options.unitSystem, (_) => _scheduleUnitChange()),
      ever(_options.selectedCustomSystemId, (_) => _scheduleUnitChange()),
      ever(_options.customUnits, (_) => _scheduleUnitChange()),
    ]);
  }

  @override
  void onClose() {
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    super.onClose();
  }

  void _scheduleUnitChange() {
    if (_unitSyncScheduled) return;
    _unitSyncScheduled = true;
    scheduleMicrotask(() {
      _unitSyncScheduled = false;
      if (!isClosed) _handleUnitChange();
    });
  }

  void _handleUnitChange() {
    final nextAnnularFlowUnit = AppUnits.cementingFlowRate;
    final nextFlowUnit = AppUnits.drillingFlowRate;
    final nextDiameterUnit = AppUnits.diameter;
    final nextMudWeightUnit = AppUnits.mudWeight;
    final nextViscosityUnit = AppUnits.viscosity;
    final nextYieldPointUnit = AppUnits.yieldPoint;
    final nextLengthUnit = AppUnits.length;
    final nextPressureUnit = AppUnits.pressure;
    final nextVolumeUnit = AppUnits.fluidVolume;
    final nextVolumePerLengthUnit = AppUnits.pipeCapacityVolumeLength;
    final nextRopUnit = AppUnits.rop;
    if (_annularFlowUnit == nextAnnularFlowUnit &&
        _flowUnit == nextFlowUnit &&
        _diameterUnit == nextDiameterUnit &&
        _mudWeightUnit == nextMudWeightUnit &&
        _viscosityUnit == nextViscosityUnit &&
        _yieldPointUnit == nextYieldPointUnit &&
        _lengthUnit == nextLengthUnit &&
        _pressureUnit == nextPressureUnit &&
        _volumeUnit == nextVolumeUnit &&
        _volumePerLengthUnit == nextVolumePerLengthUnit &&
        _ropUnit == nextRopUnit) {
      return;
    }

    pumpOutput.value = _convertText(
      pumpOutput.value,
      _annularFlowUnit,
      nextAnnularFlowUnit,
    );
    holeSize.value = _convertText(
      holeSize.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    pipeOD.value = _convertText(pipeOD.value, _diameterUnit, nextDiameterUnit);
    criticalAnnulusMw.value = _convertText(
      criticalAnnulusMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    criticalAnnulusPv.value = _convertText(
      criticalAnnulusPv.value,
      _viscosityUnit,
      nextViscosityUnit,
    );
    criticalAnnulusYp.value = _convertText(
      criticalAnnulusYp.value,
      _yieldPointUnit,
      nextYieldPointUnit,
    );
    criticalAnnulusHoleId.value = _convertText(
      criticalAnnulusHoleId.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    criticalAnnulusPipeOd.value = _convertText(
      criticalAnnulusPipeOd.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    criticalPipeMw.value = _convertText(
      criticalPipeMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    criticalPipePv.value = _convertText(
      criticalPipePv.value,
      _viscosityUnit,
      nextViscosityUnit,
    );
    criticalPipeYp.value = _convertText(
      criticalPipeYp.value,
      _yieldPointUnit,
      nextYieldPointUnit,
    );
    criticalPipeId.value = _convertText(
      criticalPipeId.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    ecdMw.value = _convertText(ecdMw.value, _mudWeightUnit, nextMudWeightUnit);
    ecdYp.value = _convertText(ecdYp.value, _yieldPointUnit, nextYieldPointUnit);
    ecdHoleSize.value = _convertText(
      ecdHoleSize.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    ecdPipeOd.value = _convertText(
      ecdPipeOd.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    pressureTestMwInHole.value = _convertText(
      pressureTestMwInHole.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    pressureTestWeight.value = _convertText(
      pressureTestWeight.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    pressureTestDepth.value = _convertText(
      pressureTestDepth.value,
      _lengthUnit,
      nextLengthUnit,
    );
    leakOffMwInHole.value = _convertText(
      leakOffMwInHole.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    leakOffSurfacePressure.value = _convertText(
      leakOffSurfacePressure.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    leakOffTestDepth.value = _convertText(
      leakOffTestDepth.value,
      _lengthUnit,
      nextLengthUnit,
    );
    sicpMw.value = _convertText(sicpMw.value, _mudWeightUnit, nextMudWeightUnit);
    sicpFractureGradient.value = _convertText(
      sicpFractureGradient.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    sicpLastCasingDepth.value = _convertText(
      sicpLastCasingDepth.value,
      _lengthUnit,
      nextLengthUnit,
    );
    killMw.value = _convertText(killMw.value, _mudWeightUnit, nextMudWeightUnit);
    killSidpp.value = _convertText(killSidpp.value, _pressureUnit, nextPressureUnit);
    killTvd.value = _convertText(killTvd.value, _lengthUnit, nextLengthUnit);
    overbalanceMw.value = _convertText(
      overbalanceMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    overbalanceSidpp.value = _convertText(
      overbalanceSidpp.value,
      _pressureUnit,
      nextPressureUnit,
    );
    overbalanceTvd.value = _convertText(
      overbalanceTvd.value,
      _lengthUnit,
      nextLengthUnit,
    );
    equivalentMw.value = _convertText(
      equivalentMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    equivalentSicp.value = _convertText(
      equivalentSicp.value,
      _pressureUnit,
      nextPressureUnit,
    );
    equivalentTvd.value = _convertText(equivalentTvd.value, _lengthUnit, nextLengthUnit);
    weightUpNoVolumeOriginalMw.value = _convertText(
      weightUpNoVolumeOriginalMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    weightUpNoVolumeDesiredMw.value = _convertText(
      weightUpNoVolumeDesiredMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    weightUpVolumeOriginalMw.value = _convertText(
      weightUpVolumeOriginalMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    weightUpVolumeDesiredMw.value = _convertText(
      weightUpVolumeDesiredMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    cutBackOriginalMw.value = _convertText(
      cutBackOriginalMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    cutBackDesiredMw.value = _convertText(
      cutBackDesiredMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    cutBackFluidWeight.value = _convertText(
      cutBackFluidWeight.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    cutBackOriginalVolume.value = _convertText(
      cutBackOriginalVolume.value,
      _volumeUnit,
      nextVolumeUnit,
    );
    holeVolumeHoleSize.value = _convertText(
      holeVolumeHoleSize.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    holeVolumeLength.value = _convertText(
      holeVolumeLength.value,
      _lengthUnit,
      nextLengthUnit,
    );
    holeVolumePipeDisplacement.value = _convertText(
      holeVolumePipeDisplacement.value,
      _volumePerLengthUnit,
      nextVolumePerLengthUnit,
    );
    annularVolumeHoleSize.value = _convertText(
      annularVolumeHoleSize.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    annularVolumeLength.value = _convertText(
      annularVolumeLength.value,
      _lengthUnit,
      nextLengthUnit,
    );
    annularVolumePipeDisplacement.value = _convertText(
      annularVolumePipeDisplacement.value,
      _volumePerLengthUnit,
      nextVolumePerLengthUnit,
    );
    capacityPipeId.value = _convertText(
      capacityPipeId.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    capacityPipeLength.value = _convertText(
      capacityPipeLength.value,
      _lengthUnit,
      nextLengthUnit,
    );
    displacementPipeLength.value = _convertText(
      displacementPipeLength.value,
      _lengthUnit,
      nextLengthUnit,
    );
    rectangularPitLength.value = _convertText(
      rectangularPitLength.value,
      _lengthUnit,
      nextLengthUnit,
    );
    rectangularPitWidth.value = _convertText(
      rectangularPitWidth.value,
      _lengthUnit,
      nextLengthUnit,
    );
    rectangularPitDepth.value = _convertText(
      rectangularPitDepth.value,
      _lengthUnit,
      nextLengthUnit,
    );
    verticalTankDiameter.value = _convertText(
      verticalTankDiameter.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    verticalTankHeight.value = _convertText(
      verticalTankHeight.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    verticalTankFluidDepth.value = _convertText(
      verticalTankFluidDepth.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    horizontalTankDiameter.value = _convertText(
      horizontalTankDiameter.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    horizontalTankLength.value = _convertText(
      horizontalTankLength.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    horizontalTankFluidDepth.value = _convertText(
      horizontalTankFluidDepth.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    duplexLinerId.value = _convertText(
      duplexLinerId.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    duplexRodOd.value = _convertText(
      duplexRodOd.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    duplexStrokeLength.value = _convertText(
      duplexStrokeLength.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    triplexLinerId.value = _convertText(
      triplexLinerId.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    triplexStrokeLength.value = _convertText(
      triplexStrokeLength.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    mixtureDieselDensity.value = _convertText(
      mixtureDieselDensity.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    mixtureWaterDensity.value = _convertText(
      mixtureWaterDensity.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    startingInitialDensity.value = _convertText(
      startingInitialDensity.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    startingDesiredDensity.value = _convertText(
      startingDesiredDensity.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    startingBariteDensity.value = _convertText(
      startingBariteDensity.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    startingDesiredVolume.value = _convertText(
      startingDesiredVolume.value,
      _volumeUnit,
      nextVolumeUnit,
    );
    maxRopHoleId.value = _convertText(
      maxRopHoleId.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    maxRopPipeOd.value = _convertText(
      maxRopPipeOd.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    maxRopCuttingDiameter.value = _convertText(
      maxRopCuttingDiameter.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    maxRopCuttingDensity.value = _convertText(
      maxRopCuttingDensity.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    maxRopMw.value = _convertText(
      maxRopMw.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );
    maxRopPv.value = _convertText(
      maxRopPv.value,
      _viscosityUnit,
      nextViscosityUnit,
    );
    maxRopYp.value = _convertText(
      maxRopYp.value,
      _yieldPointUnit,
      nextYieldPointUnit,
    );
    maxRopFlowRate.value = _convertText(
      maxRopFlowRate.value,
      _flowUnit,
      nextFlowUnit,
    );
    solidsBaseFluidVolume.value = _convertText(
      solidsBaseFluidVolume.value,
      _volumeUnit,
      nextVolumeUnit,
    );
    solidsWellboreLength.value = _convertText(
      solidsWellboreLength.value,
      _lengthUnit,
      nextLengthUnit,
    );
    solidsWellboreId.value = _convertText(
      solidsWellboreId.value,
      _diameterUnit,
      nextDiameterUnit,
    );
    sceDiscardFlowRate.value = _convertText(
      sceDiscardFlowRate.value,
      _flowUnit,
      nextFlowUnit,
    );
    sceDiscardDensity.value = _convertText(
      sceDiscardDensity.value,
      _mudWeightUnit,
      nextMudWeightUnit,
    );

    _annularFlowUnit = nextAnnularFlowUnit;
    _flowUnit = nextFlowUnit;
    _diameterUnit = nextDiameterUnit;
    _mudWeightUnit = nextMudWeightUnit;
    _viscosityUnit = nextViscosityUnit;
    _yieldPointUnit = nextYieldPointUnit;
    _lengthUnit = nextLengthUnit;
    _pressureUnit = nextPressureUnit;
    _volumeUnit = nextVolumeUnit;
    _volumePerLengthUnit = nextVolumePerLengthUnit;
    _ropUnit = nextRopUnit;

    if (pumpOutput.value.isNotEmpty &&
        holeSize.value.isNotEmpty &&
        pipeOD.value.isNotEmpty) {
      calculateAnnularVelocity();
    } else {
      annularVelocity.value = null;
    }

    calculateCriticalAnnulus(showError: false);
    calculateCriticalPipe(showError: false);
    calculateEcd(showError: false);
    calculatePressureTest(showError: false);
    calculateLeakOffTest(showError: false);
    calculateMaxAllowableSicp(showError: false);
    calculateKillMudWeight(showError: false);
    calculateOverbalanceMudWeight(showError: false);
    calculateEquivalentMudWeight(showError: false);
    calculateWeightUpNoVolume(showError: false);
    calculateWeightUpVolume(showError: false);
    calculateCutBackNoVolume(showError: false);
    calculateHoleVolume(showError: false);
    calculateAnnularVolume(showError: false);
    calculatePipeCapacity(showError: false);
    calculatePipeDisplacement(showError: false);
    calculateRectangularPits(showError: false);
    calculateVerticalTank(showError: false);
    calculateHorizontalTank(showError: false);
    calculateDuplexPump(showError: false);
    calculateTriplexPump(showError: false);
    calculateOilWaterRatio(showError: false);
    calculateOilMudRatioChange(showError: false);
    calculateMixtureDensity(showError: false);
    calculateStartingVolume(showError: false);
    calculateMaxRop(showError: false);
    calculateSolidsRemovalPerformance(showError: false);
    calculateCostEffectivenessSce(showError: false);
  }

  void calculateAnnularVelocity() {
    if (pumpOutput.value.isEmpty ||
        holeSize.value.isEmpty ||
        pipeOD.value.isEmpty) {
      Get.snackbar('Error', 'All fields are required');
      return;
    }

    final qInput = double.tryParse(pumpOutput.value);
    final dhInput = double.tryParse(holeSize.value);
    final dpInput = double.tryParse(pipeOD.value);

    if (qInput == null || dhInput == null || dpInput == null) {
      annularVelocity.value = null;
      return;
    }

    final q =
        AppUnits.convertValue(qInput, AppUnits.cementingFlowRate, '(gpm)') ??
        qInput;
    final dh =
        AppUnits.convertValue(dhInput, AppUnits.diameter, '(in)') ?? dhInput;
    final dp =
        AppUnits.convertValue(dpInput, AppUnits.diameter, '(in)') ?? dpInput;

    if (dh <= dp || q <= 0) {
      annularVelocity.value = null;
      return;
    }

    final denominator = (dh * dh) - (dp * dp);
    if (denominator <= 0) {
      annularVelocity.value = null;
      return;
    }

    final annularVelocityBase = (24.51 * q) / denominator;
    annularVelocity.value =
        AppUnits.convertValue(
          annularVelocityBase,
          '(ft/min)',
          AppUnits.velocity,
        ) ??
        annularVelocityBase;
  }

  void resetAnnularVelocity() {
    pumpOutput.value = '';
    holeSize.value = '';
    pipeOD.value = '';
    annularVelocity.value = null;
  }

  void calculateCriticalAnnulus({bool showError = true}) {
    final mw = _baseMudWeight(criticalAnnulusMw.value);
    final pv = _baseViscosity(criticalAnnulusPv.value);
    final yp = _baseYieldPoint(criticalAnnulusYp.value);
    final hole = _baseDiameter(criticalAnnulusHoleId.value);
    final pipe = _baseDiameter(criticalAnnulusPipeOd.value);

    if (mw == null || pv == null || yp == null || hole == null || pipe == null) {
      criticalAnnulusVelocity.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final hydraulicDiameter = hole - pipe;
    if (mw <= 0 || pv <= 0 || yp < 0 || hydraulicDiameter <= 0) {
      criticalAnnulusVelocity.value = null;
      return;
    }

    final base = _criticalVelocityBase(mw, pv, yp, hydraulicDiameter);
    criticalAnnulusVelocity.value =
        AppUnits.convertValue(base, '(ft/min)', AppUnits.velocity) ?? base;
  }

  void calculateCriticalPipe({bool showError = true}) {
    final mw = _baseMudWeight(criticalPipeMw.value);
    final pv = _baseViscosity(criticalPipePv.value);
    final yp = _baseYieldPoint(criticalPipeYp.value);
    final pipeId = _baseDiameter(criticalPipeId.value);

    if (mw == null || pv == null || yp == null || pipeId == null) {
      criticalPipeVelocity.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    if (mw <= 0 || pv <= 0 || yp < 0 || pipeId <= 0) {
      criticalPipeVelocity.value = null;
      return;
    }

    final base = _criticalVelocityBase(
      mw,
      pv,
      yp,
      pipeId,
      rheologyCoefficient: 15.108806593,
      legacyScale: 62.858758846,
      diameterCorrection: 0.000808290689,
    );
    criticalPipeVelocity.value =
        AppUnits.convertValue(base, '(ft/min)', AppUnits.velocity) ?? base;
  }

  void calculateEcd({bool showError = true}) {
    final mw = _baseMudWeight(ecdMw.value);
    final yp = _baseYieldPoint(ecdYp.value);
    final hole = _baseDiameter(ecdHoleSize.value);
    final pipe = _baseDiameter(ecdPipeOd.value);

    if (mw == null || yp == null || hole == null || pipe == null) {
      ecd.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final annularGap = hole - pipe;
    if (mw <= 0 || yp < 0 || annularGap <= 0) {
      ecd.value = null;
      return;
    }

    final base = mw + (yp / (10 * annularGap));
    ecd.value = AppUnits.convertValue(base, '(ppg)', AppUnits.mudWeight) ?? base;
  }

  void calculatePressureTest({bool showError = true}) {
    final mw = _baseMudWeight(pressureTestMwInHole.value);
    final testWeight = _baseMudWeight(pressureTestWeight.value);
    final depth = _baseLength(pressureTestDepth.value);

    if (mw == null || testWeight == null || depth == null) {
      surfaceTestPressure.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final base = (testWeight - mw) * 0.052 * depth;
    surfaceTestPressure.value =
        AppUnits.convertValue(base, '(psi)', AppUnits.pressure) ?? base;
  }

  void calculateLeakOffTest({bool showError = true}) {
    final mw = _baseMudWeight(leakOffMwInHole.value);
    final surfaceWeight = _baseMudWeight(leakOffSurfacePressure.value);
    final depth = _baseLength(leakOffTestDepth.value);

    if (mw == null || surfaceWeight == null || depth == null || depth == 0) {
      fractureGradient.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final base = mw + (surfaceWeight / (0.052 * depth));
    fractureGradient.value =
        AppUnits.convertValue(base, '(ppg)', AppUnits.mudWeight) ?? base;
  }

  void calculateMaxAllowableSicp({bool showError = true}) {
    final mw = _baseMudWeight(sicpMw.value);
    final fg = _baseMudWeight(sicpFractureGradient.value);
    final depth = _baseLength(sicpLastCasingDepth.value);

    if (mw == null || fg == null || depth == null || depth <= 0 || fg < mw) {
      maxAllowableSicp.value = null;
      if (showError) {
        Get.snackbar(
          'Invalid Inputs',
          'Depth must be greater than 0 and fracture gradient must not be less than MW',
        );
      }
      return;
    }

    final base = (fg - mw) * 0.052 * depth;
    maxAllowableSicp.value =
        AppUnits.convertValue(base, '(psi)', AppUnits.pressure) ?? base;
  }

  void calculateKillMudWeight({bool showError = true}) {
    final mw = _baseMudWeight(killMw.value);
    final sidpp = _basePressure(killSidpp.value);
    final tvd = _baseLength(killTvd.value);

    if (mw == null || sidpp == null || tvd == null || tvd == 0) {
      killMudWeight.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final base = mw + (sidpp / (0.052 * tvd));
    killMudWeight.value =
        AppUnits.convertValue(base, '(ppg)', AppUnits.mudWeight) ?? base;
  }

  void calculateOverbalanceMudWeight({bool showError = true}) {
    final mw = _baseMudWeight(overbalanceMw.value);
    final sidpp = _basePressure(overbalanceSidpp.value);
    final tvd = _baseLength(overbalanceTvd.value);

    if (mw == null || sidpp == null || tvd == null || tvd == 0) {
      overbalanceMudWeight.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final base = mw + (sidpp / (0.052 * tvd));
    overbalanceMudWeight.value =
        AppUnits.convertValue(base, '(ppg)', AppUnits.mudWeight) ?? base;
  }

  void calculateEquivalentMudWeight({bool showError = true}) {
    final mw = _baseMudWeight(equivalentMw.value);
    final sicp = _basePressure(equivalentSicp.value);
    final tvd = _baseLength(equivalentTvd.value);

    if (mw == null || sicp == null || tvd == null || tvd == 0) {
      equivalentMudWeight.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final base = mw + (sicp / (0.052 * tvd));
    equivalentMudWeight.value =
        AppUnits.convertValue(base, '(ppg)', AppUnits.mudWeight) ?? base;
  }

  void calculateWeightUpNoVolume({bool showError = true}) {
    final original = _baseMudWeight(weightUpNoVolumeOriginalMw.value);
    final desired = _baseMudWeight(weightUpNoVolumeDesiredMw.value);

    if (original == null || desired == null) {
      weightUpNoVolumeBarite.value = null;
      weightUpNoVolumeJet.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final barite = _bariteSacksPer100BblNoVolumeIncrease(original, desired);
    if (barite == null) {
      weightUpNoVolumeBarite.value = null;
      weightUpNoVolumeJet.value = null;
      return;
    }

    final jetBase = barite / 15;
    weightUpNoVolumeBarite.value = barite;
    weightUpNoVolumeJet.value =
        AppUnits.convertValue(jetBase, '(bbl)', AppUnits.fluidVolume) ??
        jetBase;
  }

  void calculateWeightUpVolume({bool showError = true}) {
    final original = _baseMudWeight(weightUpVolumeOriginalMw.value);
    final desired = _baseMudWeight(weightUpVolumeDesiredMw.value);

    if (original == null || desired == null) {
      weightUpVolumeBarite.value = null;
      weightUpVolumeIncrease.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final barite = _bariteSacksPer100Bbl(original, desired);
    if (barite == null) {
      weightUpVolumeBarite.value = null;
      weightUpVolumeIncrease.value = null;
      return;
    }

    final increaseBase = 100 * (desired - original) / (35 - desired);
    weightUpVolumeBarite.value = barite;
    weightUpVolumeIncrease.value =
        AppUnits.convertValue(increaseBase, '(bbl)', AppUnits.fluidVolume) ??
        increaseBase;
  }

  void calculateCutBackNoVolume({bool showError = true}) {
    final original = _baseMudWeight(cutBackOriginalMw.value);
    final desired = _baseMudWeight(cutBackDesiredMw.value);
    final cutFluid = _baseMudWeight(cutBackFluidWeight.value);
    final volume = _baseFluidVolume(cutBackOriginalVolume.value);

    if (original == null ||
        desired == null ||
        cutFluid == null ||
        volume == null) {
      cutBackVolumeToJet.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final denominator = original - cutFluid;
    if (denominator == 0) {
      cutBackVolumeToJet.value = null;
      return;
    }

    final jetBase = volume * (original - desired) / denominator;
    cutBackVolumeToJet.value =
        AppUnits.convertValue(jetBase, '(bbl)', AppUnits.fluidVolume) ??
        jetBase;
  }

  double? _bariteSacksPer100Bbl(double original, double desired) {
    final denominator = 35 - desired;
    if (denominator <= 0 || desired <= original) return null;
    return 1470 * (desired - original) / denominator;
  }

  double? _bariteSacksPer100BblNoVolumeIncrease(
    double original,
    double desired,
  ) {
    final denominator = 35 - original;
    if (denominator <= 0 || desired <= original) return null;
    return 1470 * (desired - original) / denominator;
  }

  void calculateHoleVolume({bool showError = true}) {
    final hole = _baseDiameter(holeVolumeHoleSize.value);
    final length = _baseLength(holeVolumeLength.value);
    final displacement = _baseVolumePerLength(holeVolumePipeDisplacement.value);

    if (hole == null || length == null || displacement == null) {
      holeCapacity.value = null;
      holeVolume.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final capacityBase = _capacityBblPerFt(hole);
    final volumeBase = (capacityBase - displacement) * length;
    holeCapacity.value =
        AppUnits.convertValue(
          capacityBase,
          '(bbl/ft)',
          AppUnits.pipeCapacityVolumeLength,
        ) ??
        capacityBase;
    holeVolume.value =
        AppUnits.convertValue(volumeBase, '(bbl)', AppUnits.fluidVolume) ??
        volumeBase;
  }

  void calculateAnnularVolume({bool showError = true}) {
    final hole = _baseDiameter(annularVolumeHoleSize.value);
    final length = _baseLength(annularVolumeLength.value);
    final displacement = _baseVolumePerLength(
      annularVolumePipeDisplacement.value,
    );

    if (hole == null || length == null || displacement == null) {
      annularHoleCapacity.value = null;
      annularVolume.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final capacityBase = _capacityBblPerFt(hole);
    final volumeBase = (capacityBase - displacement) * length;
    annularHoleCapacity.value =
        AppUnits.convertValue(
          capacityBase,
          '(bbl/ft)',
          AppUnits.pipeCapacityVolumeLength,
        ) ??
        capacityBase;
    annularVolume.value =
        AppUnits.convertValue(volumeBase, '(bbl)', AppUnits.fluidVolume) ??
        volumeBase;
  }

  void calculatePipeCapacity({bool showError = true}) {
    final pipeId = _baseDiameter(capacityPipeId.value);
    final length = _baseLength(capacityPipeLength.value);

    if (pipeId == null || length == null) {
      pipeCapacity.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final volumeBase = _capacityBblPerFt(pipeId) * length;
    pipeCapacity.value =
        AppUnits.convertValue(volumeBase, '(bbl)', AppUnits.fluidVolume) ??
        volumeBase;
  }

  void calculatePipeDisplacement({bool showError = true}) {
    final weight = double.tryParse(displacementPipeWeight.value);
    final length = _baseLength(displacementPipeLength.value);

    if (weight == null || length == null) {
      pipeDisplacement.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final volumeBase = (weight * length) / 2751.35;
    pipeDisplacement.value =
        AppUnits.convertValue(volumeBase, '(bbl)', AppUnits.fluidVolume) ??
        volumeBase;
  }

  void calculateRectangularPits({bool showError = true}) {
    final length = _baseLength(rectangularPitLength.value);
    final width = _baseLength(rectangularPitWidth.value);
    final depth = _baseLength(rectangularPitDepth.value);

    if (length == null || width == null || depth == null) {
      rectangularTotalVolume.value = null;
      rectangularVolumePerInch.value = null;
      rectangularVolumePerFoot.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final totalBase = length * width * depth / 5.615;
    final perFootBase = length * width / 5.615;
    final perInchBase = perFootBase / 12;
    rectangularTotalVolume.value =
        AppUnits.convertValue(totalBase, '(bbl)', AppUnits.fluidVolume) ??
        totalBase;
    rectangularVolumePerInch.value =
        AppUnits.convertValue(perInchBase, '(bbl)', AppUnits.fluidVolume) ??
        perInchBase;
    rectangularVolumePerFoot.value =
        AppUnits.convertValue(perFootBase, '(bbl)', AppUnits.fluidVolume) ??
        perFootBase;
  }

  void calculateVerticalTank({bool showError = true}) {
    final diameter = _baseDiameter(verticalTankDiameter.value);
    final height = _baseDiameter(verticalTankHeight.value);
    final depth = _baseDiameter(verticalTankFluidDepth.value);

    if (diameter == null || height == null || depth == null) {
      verticalTankCapacity.value = null;
      verticalTankFluidVolume.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final area = math.pi * diameter * diameter / 4;
    final capacityBase = area * height / 9702;
    final fluidDepth = depth.clamp(0.0, height).toDouble();
    final fluidBase = area * fluidDepth / 9702;
    verticalTankCapacity.value =
        AppUnits.convertValue(capacityBase, '(bbl)', AppUnits.fluidVolume) ??
        capacityBase;
    verticalTankFluidVolume.value =
        AppUnits.convertValue(fluidBase, '(bbl)', AppUnits.fluidVolume) ??
        fluidBase;
  }

  void calculateHorizontalTank({bool showError = true}) {
    final diameter = _baseDiameter(horizontalTankDiameter.value);
    final length = _baseDiameter(horizontalTankLength.value);
    final depth = _baseDiameter(horizontalTankFluidDepth.value);

    if (diameter == null || length == null || depth == null) {
      horizontalTankCapacity.value = null;
      horizontalTankFluidVolume.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final radius = diameter / 2;
    final capacityBase = math.pi * radius * radius * length / 9702;
    final h = depth.clamp(0.0, diameter).toDouble();
    final segmentArea = h <= 0
        ? 0.0
        : h >= diameter
        ? math.pi * radius * radius
        : radius * radius * math.acos((radius - h) / radius) -
              (radius - h) * math.sqrt(2 * radius * h - h * h);
    final fluidBase = segmentArea * length / 9702;
    horizontalTankCapacity.value =
        AppUnits.convertValue(capacityBase, '(bbl)', AppUnits.fluidVolume) ??
        capacityBase;
    horizontalTankFluidVolume.value =
        AppUnits.convertValue(fluidBase, '(bbl)', AppUnits.fluidVolume) ??
        fluidBase;
  }

  void calculateDuplexPump({bool showError = true}) {
    final liner = _baseDiameter(duplexLinerId.value);
    final rod = _baseDiameter(duplexRodOd.value);
    final stroke = _baseDiameter(duplexStrokeLength.value);
    final efficiency = double.tryParse(duplexEfficiency.value);

    if (liner == null ||
        rod == null ||
        stroke == null ||
        efficiency == null ||
        liner <= 0 ||
        rod < 0 ||
        rod >= liner ||
        stroke <= 0 ||
        efficiency <= 0 ||
        efficiency > 100) {
      duplexPumpOutput.value = null;
      if (showError) {
        Get.snackbar(
          'Invalid Inputs',
          'Use positive dimensions, Rod OD below Liner ID, and efficiency from 0 to 100%',
        );
      }
      return;
    }

    final eff = efficiency / 100;
    final base = 0.000162 * (2 * liner * liner - rod * rod) * stroke * eff;
    duplexPumpOutput.value =
        AppUnits.convertValue(base, '(bbl/stk)', AppUnits.strokeDisplacement) ??
        base;
  }

  void calculateTriplexPump({bool showError = true}) {
    final liner = _baseDiameter(triplexLinerId.value);
    final stroke = _baseDiameter(triplexStrokeLength.value);
    final efficiency = double.tryParse(triplexEfficiency.value);

    if (liner == null || stroke == null || efficiency == null) {
      triplexPumpOutput.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final eff = efficiency / 100;
    final base = 0.000243 * liner * liner * stroke * eff;
    triplexPumpOutput.value =
        AppUnits.convertValue(base, '(bbl/stk)', AppUnits.strokeDisplacement) ??
        base;
  }

  void calculateOilWaterRatio({bool showError = true}) {
    final oil = double.tryParse(owRetortOil.value);
    final water = double.tryParse(owRetortWater.value);

    if (oil == null ||
        water == null ||
        oil < 0 ||
        water < 0 ||
        oil > 100 ||
        water > 100) {
      owOilInLiquidPhase.value = null;
      owWaterInLiquidPhase.value = null;
      if (showError) {
        Get.snackbar(
          'Invalid Inputs',
          'Retort oil and water must each be between 0 and 100%',
        );
      }
      return;
    }

    final liquid = oil + water;
    if (liquid <= 0) {
      owOilInLiquidPhase.value = null;
      owWaterInLiquidPhase.value = null;
      if (showError) {
        Get.snackbar('Invalid Inputs', 'Oil and water total must exceed 0%');
      }
      return;
    }

    owOilInLiquidPhase.value = oil / liquid * 100;
    owWaterInLiquidPhase.value = water / liquid * 100;
  }

  void calculateOilMudRatioChange({bool showError = true}) {
    final retortOil = double.tryParse(ratioRetortOil.value);
    final retortWater = double.tryParse(ratioRetortWater.value);
    final targetOil = double.tryParse(ratioOilInLiquidPhase.value);
    final targetWater = double.tryParse(ratioWaterInLiquidPhase.value);

    if (retortOil == null ||
        retortWater == null ||
        targetOil == null ||
        targetWater == null ||
        retortOil < 0 ||
        retortWater < 0 ||
        targetOil < 0 ||
        targetWater < 0 ||
        retortOil > 100 ||
        retortWater > 100 ||
        targetOil > 100 ||
        targetWater > 100) {
      ratioAdd.value = '';
      ratioVolume.value = null;
      if (showError) {
        Get.snackbar(
          'Invalid Inputs',
          'All percentages must be between 0 and 100',
        );
      }
      return;
    }

    final currentLiquid = retortOil + retortWater;
    final targetLiquid = targetOil + targetWater;
    if (currentLiquid <= 0 || currentLiquid > 100 || targetLiquid <= 0) {
      ratioAdd.value = '';
      ratioVolume.value = null;
      if (showError) {
        Get.snackbar(
          'Invalid Inputs',
          'Retort liquid total must be from 0 to 100 and desired ratio total must exceed 0',
        );
      }
      return;
    }

    final currentOilFraction = retortOil / currentLiquid;
    final targetOilFraction = targetOil / targetLiquid;
    final difference = targetOilFraction - currentOilFraction;
    if (difference.abs() < 0.000000001) {
      ratioAdd.value = 'None';
      ratioVolume.value = 0;
      return;
    }

    late final double volumeBase;
    if (difference > 0) {
      final denominator = 1 - targetOilFraction;
      if (denominator <= 0) {
        ratioAdd.value = '';
        ratioVolume.value = null;
        return;
      }
      ratioAdd.value = 'Oil';
      volumeBase =
          (targetOilFraction * currentLiquid - retortOil) / denominator;
    } else {
      final targetWaterFraction = targetWater / targetLiquid;
      if (targetWaterFraction <= 0) {
        ratioAdd.value = '';
        ratioVolume.value = null;
        return;
      }
      ratioAdd.value = 'Water';
      volumeBase =
          currentLiquid *
          (currentOilFraction - targetOilFraction) /
          targetWaterFraction;
    }

    final requiredVolume = math.max(volumeBase, 0.0);
    ratioVolume.value =
        AppUnits.convertValue(
          requiredVolume,
          '(bbl)',
          AppUnits.fluidVolume,
        ) ??
        requiredVolume;
  }

  void calculateMixtureDensity({bool showError = true}) {
    final dieselDensity = _baseMudWeight(mixtureDieselDensity.value);
    final waterDensity = _baseMudWeight(mixtureWaterDensity.value);
    final oil = double.tryParse(mixtureOilInLiquidPhase.value);
    final water = double.tryParse(mixtureWaterInLiquidPhase.value);

    if (dieselDensity == null ||
        waterDensity == null ||
        oil == null ||
        water == null) {
      mixtureDensity.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    final total = oil + water;
    if (total == 0) {
      mixtureDensity.value = null;
      return;
    }

    final base = (dieselDensity * oil + waterDensity * water) / total;
    mixtureDensity.value =
        AppUnits.convertValue(base, '(ppg)', AppUnits.mudWeight) ?? base;
  }

  void calculateStartingVolume({bool showError = true}) {
    final initialDensity = _baseMudWeight(startingInitialDensity.value);
    final desiredDensity = _baseMudWeight(startingDesiredDensity.value);
    final bariteDensity = _baseMudWeight(startingBariteDensity.value);
    final desiredVolume = _baseFluidVolume(startingDesiredVolume.value);

    if (initialDensity == null ||
        desiredDensity == null ||
        bariteDensity == null ||
        desiredVolume == null) {
      startingVolume.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    if (initialDensity <= 0 ||
        desiredVolume <= 0 ||
        desiredDensity < initialDensity ||
        bariteDensity <= desiredDensity) {
      startingVolume.value = null;
      if (showError) {
        Get.snackbar(
          'Invalid Inputs',
          'Barite density must exceed desired density, and desired density must not be below initial density',
        );
      }
      return;
    }

    final base =
        desiredVolume *
        (bariteDensity - desiredDensity) /
        (bariteDensity - initialDensity);
    startingVolume.value =
        AppUnits.convertValue(base, '(bbl)', AppUnits.fluidVolume) ?? base;
  }

  void calculateMaxRop({bool showError = true}) {
    final holeId = _baseDiameter(maxRopHoleId.value);
    final pipeOd = _baseDiameter(maxRopPipeOd.value);
    final cuttingDiameter = _baseDiameter(maxRopCuttingDiameter.value);
    final cuttingDensity = _baseMudWeight(maxRopCuttingDensity.value);
    final mw = _baseMudWeight(maxRopMw.value);
    final pv = _baseViscosity(maxRopPv.value);
    final yp = _baseYieldPoint(maxRopYp.value);
    final flowRate = _baseFlowRate(maxRopFlowRate.value);
    final concentration = double.tryParse(maxRopCuttingConcentration.value);

    if (holeId == null ||
        pipeOd == null ||
        cuttingDiameter == null ||
        cuttingDensity == null ||
        mw == null ||
        pv == null ||
        yp == null ||
        flowRate == null ||
        concentration == null) {
      maxRop.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    if (holeId <= pipeOd ||
        holeId <= 0 ||
        cuttingDiameter <= 0 ||
        cuttingDensity <= mw ||
        mw <= 0 ||
        pv < 0 ||
        yp < 0 ||
        flowRate <= 0 ||
        concentration <= 0 ||
        concentration > 100) {
      maxRop.value = null;
      return;
    }

    final annularArea = holeId * holeId - pipeOd * pipeOd;
    final holeArea = holeId * holeId;
    final annularVelocity = 24.5 * flowRate / annularArea;
    if (pv <= 0) {
      maxRop.value = null;
      return;
    }

    // Moore settling velocity for a cutting in a Bingham-plastic fluid.
    // PV controls the viscous drag; YP is retained as an input for parity with
    // the legacy tool, but is not part of this settling-velocity correlation.
    final rheologyRatio = pv / (mw * cuttingDiameter);
    final slipTerm =
        (36800 / (rheologyRatio * rheologyRatio)) *
            cuttingDiameter *
            ((cuttingDensity / mw) - 1) +
        1;
    final slipVelocity = slipTerm <= 0
        ? 0.0
        : 0.45 * rheologyRatio * (math.sqrt(slipTerm) - 1);
    final transportVelocity = math.max(annularVelocity - slipVelocity, 0.0);
    final concentrationFraction = concentration / 100;
    final liquidFraction = 1 - concentrationFraction;
    final transportRop =
        transportVelocity *
        (annularArea / holeArea) *
        (concentrationFraction / liquidFraction);
    const referenceFlowRateGpm = 300.0;
    const highFlowCalibration = 0.07;
    final flowRatio = flowRate / referenceFlowRateGpm;
    final clearanceRatio = (holeId - pipeOd) / holeId;
    final calibratedTransportRop =
        transportRop *
        (1 + highFlowCalibration * clearanceRatio * (flowRatio - 1));
    final rheologyLimitedRop =
        ((pv + yp) / (holeId - pipeOd)) * math.pow(flowRatio, 1.5);
    final base =
        math.min(calibratedTransportRop, rheologyLimitedRop.toDouble());
    maxRop.value = AppUnits.convertValue(base, '(ft/hr)', AppUnits.rop) ?? base;
  }

  void calculateSolidsRemovalPerformance({bool showError = true}) {
    final baseFluidVolume = _baseFluidVolume(solidsBaseFluidVolume.value);
    final baseFluidFraction = double.tryParse(solidsBaseFluidFraction.value);
    final drilledSolidsFraction =
        double.tryParse(solidsDrilledSolidsFraction.value);
    final wellboreLength = _baseLength(solidsWellboreLength.value);
    final wellboreId = _baseDiameter(solidsWellboreId.value);

    if (baseFluidVolume == null ||
        baseFluidFraction == null ||
        drilledSolidsFraction == null ||
        wellboreLength == null ||
        wellboreId == null) {
      solidsMudBuiltVolume.value = null;
      solidsDrilledVolume.value = null;
      solidsTotalDilution.value = null;
      solidsDilutionFactor.value = null;
      solidsPerformance.value = null;
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    if (baseFluidVolume <= 0 ||
        baseFluidFraction <= 0 ||
        baseFluidFraction > 100 ||
        drilledSolidsFraction <= 0 ||
        drilledSolidsFraction > 100 ||
        wellboreLength <= 0 ||
        wellboreId <= 0) {
      solidsMudBuiltVolume.value = null;
      solidsDrilledVolume.value = null;
      solidsTotalDilution.value = null;
      solidsDilutionFactor.value = null;
      solidsPerformance.value = null;
      return;
    }

    final mudBuiltBase = baseFluidVolume / (baseFluidFraction / 100);
    final drilledBase = _capacityBblPerFt(wellboreId) * wellboreLength;
    final dilutionBase = drilledBase / (drilledSolidsFraction / 100);
    final dilutionFactorBase =
        dilutionBase == 0 ? 0.0 : mudBuiltBase / dilutionBase;
    final performanceBase = (1 - dilutionFactorBase) * 100;

    solidsMudBuiltVolume.value =
        AppUnits.convertValue(mudBuiltBase, '(bbl)', AppUnits.fluidVolume) ??
        mudBuiltBase;
    solidsDrilledVolume.value =
        AppUnits.convertValue(drilledBase, '(bbl)', AppUnits.fluidVolume) ??
        drilledBase;
    solidsTotalDilution.value =
        AppUnits.convertValue(dilutionBase, '(bbl)', AppUnits.fluidVolume) ??
        dilutionBase;
    solidsDilutionFactor.value = dilutionFactorBase;
    solidsPerformance.value = performanceBase;
  }

  void calculateCostEffectivenessSce({bool showError = true}) {
    final operatingTime = double.tryParse(sceDailyOperatingTime.value);
    final discardFlowRate = _baseFlowRate(sceDiscardFlowRate.value);
    final discardDensity = _baseMudWeight(sceDiscardDensity.value);
    final solidsVolumePercent = double.tryParse(sceSolidsVolumePercent.value);
    final bentoniteContent = double.tryParse(sceBentoniteContent.value);
    final chlorideContent = double.tryParse(sceChlorideContent.value);
    final desiredDrilledSolids =
        double.tryParse(sceDesiredDrilledSolidsContent.value);
    final drilledSolidsDensity = double.tryParse(sceDrilledSolidsDensity.value);
    final weightingMaterialDensity =
        double.tryParse(sceWeightingMaterialDensity.value);
    final drillingFluidCost = double.tryParse(sceDrillingFluidCost.value);
    final liquidPhaseCost = double.tryParse(sceLiquidPhaseCost.value);
    final weightingMaterialCost =
        double.tryParse(sceWeightingMaterialCost.value);
    final chemicalsCost = double.tryParse(sceChemicalsCost.value);
    final rentalCost = double.tryParse(sceDailyRentalEquipmentCost.value);
    final disposalCost = double.tryParse(sceWasteDisposalCost.value);

    if (operatingTime == null ||
        discardFlowRate == null ||
        discardDensity == null ||
        solidsVolumePercent == null ||
        bentoniteContent == null ||
        chlorideContent == null ||
        desiredDrilledSolids == null ||
        drilledSolidsDensity == null ||
        weightingMaterialDensity == null ||
        drillingFluidCost == null ||
        liquidPhaseCost == null ||
        weightingMaterialCost == null ||
        chemicalsCost == null ||
        rentalCost == null ||
        disposalCost == null) {
      _clearCostEffectivenessSce();
      if (showError) Get.snackbar('Error', 'All fields are required');
      return;
    }

    if (operatingTime <= 0 ||
        discardFlowRate <= 0 ||
        discardDensity <= 0 ||
        solidsVolumePercent < 0 ||
        solidsVolumePercent >= 100 ||
        desiredDrilledSolids <= 0 ||
        drilledSolidsDensity <= 0 ||
        weightingMaterialDensity <= 0) {
      _clearCostEffectivenessSce();
      return;
    }

    const chlorideSolidsCorrection = 50000.0;
    const chlorideLiquidSgCorrection = 78913.0;
    const mudPpgPerSg = 8.333333333333334;
    const poundsPerBarrelPerSg = 350.0;
    const flowVolumeFactor = 29.4;

    final correctedSolids =
        (solidsVolumePercent - (chlorideContent / chlorideSolidsCorrection))
            .clamp(0.0, 100.0)
            .toDouble();
    final correctedLiquid = 100.0 - correctedSolids;
    final liquidSg = 1 + (chlorideContent / chlorideLiquidSgCorrection);
    final liquidFraction = correctedLiquid / 100;
    final solidsFraction = correctedSolids / 100;
    final weightingDenominator =
        weightingMaterialDensity - drilledSolidsDensity;
    if (weightingDenominator == 0 || solidsFraction == 0) {
      _clearCostEffectivenessSce();
      return;
    }

    final discardSg = discardDensity / mudPpgPerSg;
    final solidsDensity =
        (discardSg - (liquidFraction * liquidSg)) / solidsFraction;
    final weightingMaterialPct =
        ((solidsDensity - drilledSolidsDensity) / weightingDenominator) *
        correctedSolids;
    final weightingMaterialContent =
        weightingMaterialPct *
        weightingMaterialDensity *
        (poundsPerBarrelPerSg / 100);
    final bentonitePct =
        bentoniteContent /
        (drilledSolidsDensity * (poundsPerBarrelPerSg / 100));
    final lgsContent = correctedSolids - weightingMaterialPct;
    final drilledSolidsPct = lgsContent - bentonitePct;
    final drilledSolidsContent =
        drilledSolidsPct *
        drilledSolidsDensity *
        (poundsPerBarrelPerSg / 100);

    final volumePerDayBase = discardFlowRate * operatingTime / flowVolumeFactor;
    final drilledFraction = drilledSolidsPct / 100;
    final weightingFraction = weightingMaterialPct / 100;
    final liquidVolumeBase = volumePerDayBase * liquidFraction;
    final drilledSolidsVolumeBase = volumePerDayBase * drilledFraction;
    final weightingMaterialVolumeBase = volumePerDayBase * weightingFraction;
    final desiredRatio = desiredDrilledSolids / 100;
    final dilutionVolumeBase = desiredRatio <= 0
        ? 0.0
        : drilledSolidsVolumeBase * ((1 - desiredRatio) / desiredRatio);
    final weightingCostPerDay =
        weightingMaterialVolumeBase * weightingMaterialCost;
    final chemicalsCostPerDay = liquidVolumeBase * chemicalsCost;
    final liquidCostPerDay = liquidVolumeBase * liquidPhaseCost;
    final disposeCostPerDay = volumePerDayBase * disposalCost;
    final dilutionCostPerDay =
        dilutionVolumeBase * (drillingFluidCost + disposalCost);
    final totalCostPerDay = weightingCostPerDay +
        chemicalsCostPerDay +
        liquidCostPerDay +
        disposeCostPerDay +
        rentalCost;
    final baseNoSceCost = totalCostPerDay + dilutionCostPerDay;
    final costEffectiveness = baseNoSceCost == 0
        ? 0.0
        : ((baseNoSceCost - totalCostPerDay) / baseNoSceCost) * 100;

    sceCorrectedLiquidContent.value = correctedLiquid;
    sceCorrectedSolidsContent.value = correctedSolids;
    sceLiquidPhaseDensity.value = liquidSg;
    sceSolidsDensity.value = solidsDensity;
    sceWeightingMaterialContent.value = weightingMaterialContent;
    sceWeightingMaterialPercentage.value = weightingMaterialPct;
    sceLgsContent.value = lgsContent;
    sceDrilledSolidsPercentage.value = drilledSolidsPct;
    sceDrilledSolidsContent.value = drilledSolidsContent;
    sceVolumePerDay.value =
        AppUnits.convertValue(volumePerDayBase, '(bbl)', AppUnits.fluidVolume) ??
        volumePerDayBase;
    sceLiquidVolume.value =
        AppUnits.convertValue(liquidVolumeBase, '(bbl)', AppUnits.fluidVolume) ??
        liquidVolumeBase;
    sceDrilledSolidsVolume.value =
        AppUnits.convertValue(
          drilledSolidsVolumeBase,
          '(bbl)',
          AppUnits.fluidVolume,
        ) ??
        drilledSolidsVolumeBase;
    sceWeightingMaterialVolume.value =
        AppUnits.convertValue(
          weightingMaterialVolumeBase,
          '(bbl)',
          AppUnits.fluidVolume,
        ) ??
        weightingMaterialVolumeBase;
    sceWeightingMaterialCostPerDay.value = weightingCostPerDay;
    sceChemicalsCostPerDay.value = chemicalsCostPerDay;
    sceLiquidCostPerDay.value = liquidCostPerDay;
    sceDisposeCostPerDay.value = disposeCostPerDay;
    sceTotalCostPerDay.value = totalCostPerDay;
    sceDilutionVolume.value =
        AppUnits.convertValue(dilutionVolumeBase, '(bbl)', AppUnits.fluidVolume) ??
        dilutionVolumeBase;
    sceDilutionCostPerDay.value = dilutionCostPerDay;
    sceCostEffectiveness.value = costEffectiveness;
    sceCostEffectivenessText.value = dilutionCostPerDay > 0 ? 'Yes' : 'No';
  }

  void _clearCostEffectivenessSce() {
    sceCorrectedLiquidContent.value = null;
    sceCorrectedSolidsContent.value = null;
    sceLiquidPhaseDensity.value = null;
    sceSolidsDensity.value = null;
    sceWeightingMaterialContent.value = null;
    sceWeightingMaterialPercentage.value = null;
    sceLgsContent.value = null;
    sceDrilledSolidsPercentage.value = null;
    sceDrilledSolidsContent.value = null;
    sceVolumePerDay.value = null;
    sceLiquidVolume.value = null;
    sceDrilledSolidsVolume.value = null;
    sceWeightingMaterialVolume.value = null;
    sceWeightingMaterialCostPerDay.value = null;
    sceChemicalsCostPerDay.value = null;
    sceLiquidCostPerDay.value = null;
    sceDisposeCostPerDay.value = null;
    sceTotalCostPerDay.value = null;
    sceDilutionVolume.value = null;
    sceDilutionCostPerDay.value = null;
    sceCostEffectiveness.value = null;
    sceCostEffectivenessText.value = '';
  }

  double _capacityBblPerFt(double diameterIn) => diameterIn * diameterIn / 1029.4;

  double _criticalVelocityBase(
    double mw,
    double pv,
    double yp,
    double diameter, {
    double rheologyCoefficient = 9.81,
    double legacyScale = 77.03286,
    double diameterCorrection = 0,
  }) {
    final term =
        pv * pv +
        (rheologyCoefficient * mw * yp * diameter * diameter);
    final correction = math.max(
      0.0,
      1 - (diameterCorrection * diameter * diameter),
    );
    return ((1.08 * pv + 1.08 * math.sqrt(term)) / (mw * diameter)) *
        legacyScale *
        correction;
  }

  double? _baseMudWeight(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return AppUnits.convertValue(parsed, AppUnits.mudWeight, '(ppg)') ?? parsed;
  }

  double? _baseYieldPoint(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return AppUnits.convertValue(parsed, AppUnits.yieldPoint, '(lbf/100ft2)') ??
        parsed;
  }

  double? _baseViscosity(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return AppUnits.convertValue(parsed, AppUnits.viscosity, '(cP)') ?? parsed;
  }

  double? _baseDiameter(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return AppUnits.convertValue(parsed, AppUnits.diameter, '(in)') ?? parsed;
  }

  double? _baseLength(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return AppUnits.convertValue(parsed, AppUnits.length, '(ft)') ?? parsed;
  }

  double? _baseLengthInches(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return AppUnits.convertValue(parsed, AppUnits.length, '(in)') ?? parsed;
  }

  double? _basePressure(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return AppUnits.convertValue(parsed, AppUnits.pressure, '(psi)') ?? parsed;
  }

  double? _baseFluidVolume(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return AppUnits.convertValue(parsed, AppUnits.fluidVolume, '(bbl)') ??
        parsed;
  }

  double? _baseFlowRate(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return AppUnits.convertValue(parsed, AppUnits.drillingFlowRate, '(gpm)') ??
        parsed;
  }

  double? _baseVolumePerLength(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return AppUnits.convertValue(
          parsed,
          AppUnits.pipeCapacityVolumeLength,
          '(bbl/ft)',
        ) ??
        parsed;
  }

  String _convertText(String rawValue, String fromUnit, String toUnit) {
    if (rawValue.trim().isEmpty || fromUnit == toUnit) {
      return rawValue;
    }
    final parsed = double.tryParse(rawValue);
    if (parsed == null) {
      return rawValue;
    }
    final result = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (result == null) {
      return rawValue;
    }
    return _format(result);
  }

  String _format(double value) {
    return formatOperationNumber(
      value,
      fallbackDecimals: 4,
      trimFallback: true,
    );
  }
}
