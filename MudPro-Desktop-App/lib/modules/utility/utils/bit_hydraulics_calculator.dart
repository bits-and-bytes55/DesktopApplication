class BitHydraulicsInputs {
  final double mudWeightPpg;
  final double flowRateGpm;
  final double standpipePressurePsi;
  final double totalFlowAreaIn2;
  final double? bitSizeIn;
  final double dhToolsPressureLossPsi;
  final double motorPressureLossPsi;

  const BitHydraulicsInputs({
    required this.mudWeightPpg,
    required this.flowRateGpm,
    required this.standpipePressurePsi,
    required this.totalFlowAreaIn2,
    this.bitSizeIn,
    this.dhToolsPressureLossPsi = 0,
    this.motorPressureLossPsi = 0,
  });
}

class BitHydraulicsSnapshot {
  final double nozzleAreaIn2;
  final double nozzleVelocityFtPerSec;
  final double bitPressureDropPsi;
  final double hydraulicHp;
  final double? hydraulicHpPerArea;
  final double pressureDropPercent;
  final double? jetImpactForceLbf;
  final double? flowVelocityFtPerSec;

  const BitHydraulicsSnapshot({
    required this.nozzleAreaIn2,
    required this.nozzleVelocityFtPerSec,
    required this.bitPressureDropPsi,
    required this.hydraulicHp,
    required this.hydraulicHpPerArea,
    required this.pressureDropPercent,
    required this.jetImpactForceLbf,
    required this.flowVelocityFtPerSec,
  });
}

BitHydraulicsSnapshot? calculateBitHydraulics(BitHydraulicsInputs inputs) {
  if (inputs.flowRateGpm <= 0 ||
      inputs.standpipePressurePsi <= 0 ||
      inputs.totalFlowAreaIn2 <= 0) {
    return null;
  }

  final resolvedPressureLoss =
      inputs.standpipePressurePsi -
      inputs.dhToolsPressureLossPsi -
      inputs.motorPressureLossPsi;
  final bitPressureDropPsi = resolvedPressureLoss > 0
      ? resolvedPressureLoss
      : inputs.standpipePressurePsi * 0.65;

  final nozzleVelocityFtPerSec =
      (0.408 * inputs.flowRateGpm) / inputs.totalFlowAreaIn2;
  final hydraulicHp = (bitPressureDropPsi * inputs.flowRateGpm) / 1714;
  final pressureDropPercent =
      (bitPressureDropPsi / inputs.standpipePressurePsi) * 100;

  final bitSizeIn = inputs.bitSizeIn;
  final bitAreaIn2 = bitSizeIn != null && bitSizeIn > 0
      ? 0.785 * bitSizeIn * bitSizeIn
      : null;

  final hydraulicHpPerArea = bitAreaIn2 != null && bitAreaIn2 > 0
      ? hydraulicHp / bitAreaIn2
      : null;
  final flowVelocityFtPerSec = bitAreaIn2 != null && bitAreaIn2 > 0
      ? (0.408 * inputs.flowRateGpm) / bitAreaIn2
      : null;
  final jetImpactForceLbf = inputs.mudWeightPpg > 0
      ? 0.01823 *
            inputs.mudWeightPpg *
            inputs.flowRateGpm *
            nozzleVelocityFtPerSec
      : null;

  return BitHydraulicsSnapshot(
    nozzleAreaIn2: inputs.totalFlowAreaIn2,
    nozzleVelocityFtPerSec: nozzleVelocityFtPerSec,
    bitPressureDropPsi: bitPressureDropPsi,
    hydraulicHp: hydraulicHp,
    hydraulicHpPerArea: hydraulicHpPerArea,
    pressureDropPercent: pressureDropPercent,
    jetImpactForceLbf: jetImpactForceLbf,
    flowVelocityFtPerSec: flowVelocityFtPerSec,
  );
}
