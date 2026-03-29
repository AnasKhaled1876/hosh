import test from "node:test";
import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";
import {
  buildAggregatedHotspot,
  deriveHotspot,
  isDuplicateReport,
  type ReportDocument,
} from "./reportAggregation.js";

const baseReport: ReportDocument = {
  userId: "user-1",
  lat: 30.0444,
  lng: 31.2357,
  timestamp: Timestamp.fromDate(new Date("2026-03-29T12:00:00Z")),
  severity: "high",
  behavior: "aggressive",
  dogCount: 2,
  anonymous: true,
  description: "Aggressive dogs near the gate",
  reportSource: "manual",
};

test("deriveHotspot builds a stable hotspot cell", () => {
  const hotspot = deriveHotspot(baseReport);
  assert.equal(hotspot.hotspotId.startsWith("cell_"), true);
  assert.equal(hotspot.dangerLevel, "danger");
});

test("buildAggregatedHotspot increments report count and preserves danger", () => {
  const hotspot = deriveHotspot(baseReport);
  const merged = buildAggregatedHotspot({
    report: baseReport,
    reportId: "report-1",
    derivedHotspot: hotspot,
    existingHotspot: {
      reportCount: 3,
      dangerLevel: "danger",
      createdAt: Timestamp.fromDate(new Date("2026-03-29T11:00:00Z")),
    },
  });

  assert.equal(merged.reportCount, 4);
  assert.equal(merged.dangerLevel, "danger");
});

test("isDuplicateReport suppresses same user in same cell within 15 minutes", () => {
  const hotspot = deriveHotspot(baseReport);
  const result = isDuplicateReport({
    reportId: "report-2",
    report: baseReport,
    derivedHotspotId: hotspot.hotspotId,
    candidates: [
      {
        id: "report-1",
        data: {
          ...baseReport,
          timestamp: Timestamp.fromDate(new Date("2026-03-29T11:50:00Z")),
        },
      },
    ],
  });

  assert.equal(result.isDuplicate, true);
});
