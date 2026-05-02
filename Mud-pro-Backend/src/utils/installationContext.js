import { AsyncLocalStorage } from "node:async_hooks";

const storage = new AsyncLocalStorage();

export const INSTALLATION_HEADER = "x-mudpro-installation-id";

export const normalizeInstallationId = (value) => {
  const text = String(value ?? "").trim();
  return /^[A-Za-z0-9_-]{16,80}$/.test(text) ? text : "";
};

export const readInstallationId = (req) =>
  normalizeInstallationId(
    req.headers?.[INSTALLATION_HEADER] ??
      req.headers?.["x-installation-id"] ??
      req.query?.installationId ??
      req.body?.installationId
  );

export const runWithInstallationId = (installationId, callback) =>
  storage.run({ installationId: normalizeInstallationId(installationId) }, callback);

export const currentInstallationId = () =>
  storage.getStore()?.installationId || "";

export const installationContextMiddleware = (req, _res, next) => {
  const installationId = readInstallationId(req);
  req.installationId = installationId;
  runWithInstallationId(installationId, next);
};
