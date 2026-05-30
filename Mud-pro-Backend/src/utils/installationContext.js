import { AsyncLocalStorage } from "node:async_hooks";

const storage = new AsyncLocalStorage();

export const INSTALLATION_HEADER = "x-mudpro-installation-id";
export const MACHINE_HEADER = "x-mudpro-machine-key";

export const normalizeInstallationId = (value) => {
  const text = String(value ?? "").trim();
  return /^[A-Za-z0-9_-]{16,80}$/.test(text) ? text : "";
};

export const readInstallationId = (req) =>
  normalizeInstallationId(
    req.headers?.[INSTALLATION_HEADER] ??
      req.headers?.["x-installation-id"]
  );

export const normalizeMachineKey = (value) => {
  const text = String(value ?? "").trim();
  return /^[A-Za-z0-9_-]{8,160}$/.test(text) ? text : "";
};

export const readMachineKey = (req) =>
  normalizeMachineKey(
    req.headers?.[MACHINE_HEADER] ?? req.headers?.["x-machine-key"]
  );

export const runWithInstallationId = (installationId, callback) =>
  storage.run(
    { installationId: normalizeInstallationId(installationId) },
    callback
  );

export const runWithInstallationContext = (
  installationId,
  machineKey,
  callback
) =>
  storage.run(
    {
      installationId: normalizeInstallationId(installationId),
      machineKey: normalizeMachineKey(machineKey),
    },
    callback
  );

export const currentInstallationId = () =>
  storage.getStore()?.installationId || "";

export const currentMachineKey = () => storage.getStore()?.machineKey || "";

export const installationContextMiddleware = (req, _res, next) => {
  const installationId = readInstallationId(req);
  const machineKey = readMachineKey(req);
  req.installationId = installationId;
  req.machineKey = machineKey;
  runWithInstallationContext(installationId, machineKey, next);
};

export const requireInstallationContext = (req, res, next) => {
  if (req.method === "OPTIONS") {
    return next();
  }

  if (!req.installationId || !req.machineKey) {
    return res.status(428).json({
      success: false,
      message: "Installation id and machine key are required",
    });
  }

  return next();
};
