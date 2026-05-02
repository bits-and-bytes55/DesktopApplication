import mongoose from "mongoose";
import { currentInstallationId } from "../utils/installationContext.js";

const hasOwn = (object, key) =>
  Object.prototype.hasOwnProperty.call(object || {}, key);

const applyInstallationFilter = (query) => {
  const installationId = currentInstallationId();
  if (!installationId) return;
  if (!query.model?.schema?.path("installationId")) return;

  const filter = query.getFilter();
  if (!hasOwn(filter, "installationId")) {
    query.where({ installationId });
  }

  const update = query.getUpdate?.();
  if (!update || typeof update !== "object") return;

  const hasUpdateOperator = Object.keys(update).some((key) => key.startsWith("$"));
  if (hasUpdateOperator) {
    update.$setOnInsert = {
      ...(update.$setOnInsert || {}),
      installationId,
    };
    return;
  }

  if (!hasOwn(update, "installationId")) {
    update.installationId = installationId;
  }
};

const setDocumentInstallation = (document) => {
  const installationId = currentInstallationId();
  if (!installationId || !document) return;
  if (!document.installationId) {
    document.installationId = installationId;
  }
};

const installationScopePlugin = (schema) => {
  if (!schema.path("installationId")) {
    schema.add({
      installationId: {
        type: String,
        default: "",
        index: true,
      },
    });
  }

  schema.pre("validate", function setInstallationOnValidate(next) {
    setDocumentInstallation(this);
    next();
  });

  schema.pre("insertMany", function setInstallationOnInsertMany(next, docs) {
    if (Array.isArray(docs)) {
      docs.forEach(setDocumentInstallation);
    }
    next();
  });

  const scopedQueryOps = [
    "countDocuments",
    "deleteMany",
    "deleteOne",
    "find",
    "findOne",
    "findOneAndDelete",
    "findOneAndRemove",
    "findOneAndReplace",
    "findOneAndUpdate",
    "replaceOne",
    "updateMany",
    "updateOne",
  ];

  for (const op of scopedQueryOps) {
    schema.pre(op, function scopeQuery(next) {
      applyInstallationFilter(this);
      next();
    });
  }

  schema.pre("aggregate", function scopeAggregate(next) {
    const installationId = currentInstallationId();
    if (!installationId || !schema.path("installationId")) {
      next();
      return;
    }

    const pipeline = this.pipeline();
    const stage = { $match: { installationId } };
    if (pipeline[0]?.$geoNear) {
      pipeline.splice(1, 0, stage);
    } else {
      pipeline.unshift(stage);
    }
    next();
  });
};

mongoose.plugin(installationScopePlugin);
