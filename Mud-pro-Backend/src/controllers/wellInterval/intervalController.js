import { Interval, IntervalGroup } from "../../modules/wellInterval/intervalModel.js";

// ════════════════════════════════════════════════════════════════════
//  HELPERS
// ════════════════════════════════════════════════════════════════════

/** Re-number the `order` field for all intervals + groups of a well
 *  so the list is 0-based contiguous after any insert / delete. */
async function reorder(wellId) {
  const intervals = await Interval.find({ wellId }).sort({ order: 1 });
  const groups    = await IntervalGroup.find({ wellId }).sort({ order: 1 });

  // Merge into one sortable list, sort by current order, re-index
  const combined = [
    ...intervals.map(d => ({ type: "interval", doc: d })),
    ...groups.map(d    => ({ type: "group",    doc: d })),
  ].sort((a, b) => a.doc.order - b.doc.order);

  await Promise.all(
    combined.map((item, idx) =>
      item.type === "interval"
        ? Interval.findByIdAndUpdate(item.doc._id, { order: idx })
        : IntervalGroup.findByIdAndUpdate(item.doc._id, { order: idx })
    )
  );
}

// ════════════════════════════════════════════════════════════════════
//  INTERVALS — CRUD
// ════════════════════════════════════════════════════════════════════

/** GET /api/intervals/:wellId
 *  Returns all intervals + groups for a well, merged and sorted. */
export const getIntervals = async (req, res) => {
  try {
    const { wellId } = req.params;

    const intervals = await Interval.find({ wellId }).sort({ order: 1 }).lean();
    const groups    = await IntervalGroup.find({ wellId }).sort({ order: 1 }).lean();

    // Merge: type tag so Flutter knows what each item is
    const list = [
      ...intervals.map(d => ({ ...d, _type: "interval" })),
      ...groups.map(d    => ({ ...d, _type: "group"    })),
    ].sort((a, b) => a.order - b.order);

    res.status(200).json({ success: true, data: list });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/** POST /api/intervals
 *  Body: { wellId, name?, insertAfterOrder? }
 *  insertAfterOrder: the `order` value of the interval to insert AFTER.
 *  If omitted → append at end.
 *  To insert BEFORE index N, pass insertAfterOrder = N - 1. */
export const createInterval = async (req, res) => {
  try {
    const { wellId, name, insertAfterOrder } = req.body;
    if (!wellId) return res.status(400).json({ success: false, message: "wellId required" });

    // Shift everything after the insert point
    const insertAt =
      insertAfterOrder !== undefined ? Number(insertAfterOrder) + 1 : Infinity;

    if (insertAt !== Infinity) {
      await Interval.updateMany(
        { wellId, order: { $gte: insertAt } },
        { $inc: { order: 1 } }
      );
      await IntervalGroup.updateMany(
        { wellId, order: { $gte: insertAt } },
        { $inc: { order: 1 } }
      );
    }

    // Count existing to find default order for append
    const totalCount = await Interval.countDocuments({ wellId }) +
                       await IntervalGroup.countDocuments({ wellId });

    const interval = await Interval.create({
      wellId,
      name: name || "New Interval",
      order: insertAt === Infinity ? totalCount : insertAt,
    });

    res.status(201).json({ success: true, data: interval });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/** PUT /api/intervals/:id
 *  Update name + all General tab fields. */
export const updateInterval = async (req, res) => {
  try {
    const updated = await Interval.findByIdAndUpdate(
      req.params.id,
      { $set: req.body },
      { new: true, runValidators: true }
    );
    if (!updated) return res.status(404).json({ success: false, message: "Not found" });
    res.status(200).json({ success: true, data: updated });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/** DELETE /api/intervals/:id */
export const deleteInterval = async (req, res) => {
  try {
    const interval = await Interval.findByIdAndDelete(req.params.id);
    if (!interval) return res.status(404).json({ success: false, message: "Not found" });

    // Remove from any group that contains it
    await IntervalGroup.updateMany(
      { wellId: interval.wellId },
      { $pull: { intervalIds: interval._id } }
    );

    await reorder(interval.wellId);
    res.status(200).json({ success: true, message: "Deleted" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ════════════════════════════════════════════════════════════════════
//  GROUPS — CRUD
// ════════════════════════════════════════════════════════════════════

/** POST /api/intervals/groups
 *  Body: { wellId, name, intervalIds[] }
 *  Creates a group and assigns those intervals to it. */
export const createGroup = async (req, res) => {
  try {
    const { wellId, name, intervalIds } = req.body;
    if (!wellId || !name) {
      return res.status(400).json({ success: false, message: "wellId and name required" });
    }

    // Find the minimum order among the selected intervals → group sits there
    const members = await Interval.find({ _id: { $in: intervalIds } }).sort({ order: 1 });
    if (!members.length) {
      return res.status(400).json({ success: false, message: "No valid intervals selected" });
    }

    const groupOrder = members[0].order;

    // Mark each interval with this groupId (we'll set after creation)
    const group = await IntervalGroup.create({
      wellId,
      name,
      intervalIds,
      order: groupOrder,
    });

    await Interval.updateMany(
      { _id: { $in: intervalIds } },
      { $set: { groupId: group._id } }
    );

    await reorder(wellId);

    // Return fresh full list
    const intervals = await Interval.find({ wellId }).sort({ order: 1 }).lean();
    const groups    = await IntervalGroup.find({ wellId }).sort({ order: 1 }).lean();
    const list = [
      ...intervals.map(d => ({ ...d, _type: "interval" })),
      ...groups.map(d    => ({ ...d, _type: "group"    })),
    ].sort((a, b) => a.order - b.order);

    res.status(201).json({ success: true, data: list });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/** DELETE /api/intervals/groups/:id
 *  Removes the group. The intervals themselves remain (ungrouped). */
export const deleteGroup = async (req, res) => {
  try {
    const group = await IntervalGroup.findByIdAndDelete(req.params.id);
    if (!group) return res.status(404).json({ success: false, message: "Not found" });

    // Un-assign groupId from member intervals
    await Interval.updateMany(
      { groupId: group._id },
      { $set: { groupId: null } }
    );

    await reorder(group.wellId);
    res.status(200).json({ success: true, message: "Group deleted, intervals retained" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/** PATCH /api/intervals/groups/:id/collapse
 *  Toggle collapsed state. */
export const toggleGroupCollapse = async (req, res) => {
  try {
    const { collapsed } = req.body;
    const group = await IntervalGroup.findByIdAndUpdate(
      req.params.id,
      { $set: { collapsed } },
      { new: true }
    );
    res.status(200).json({ success: true, data: group });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};