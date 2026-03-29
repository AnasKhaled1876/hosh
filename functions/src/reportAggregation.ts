import assert from "node:assert/strict";
import { Timestamp } from "firebase-admin/firestore";

export const HOTSPOT_GRID_SIZE_DEGREES = 0.0015;
export const HOTSPOT_BASE_RADIUS_METERS = 140;
export const HOTSPOT_MAX_RADIUS_METERS = 320;
export const DUPLICATE_WINDOW_MS = 15 * 60 * 1000;

export type ReportSeverity = "low" | "caution" | "high";
export type DogBehavior = "calm" | "barking" | "chasing" | "aggressive";
export type DangerLevel = "caution" | "danger";
export type AggregationStatus = "aggregated" | "duplicate" | "invalid";

export interface ReportDocument {
  userId: string;
  lat: number;
  lng: number;
  timestamp: Timestamp;
  severity: ReportSeverity;
  behavior: DogBehavior;
  dogCount: number;
  anonymous: boolean;
  description?: string | null;
  photoUrl?: string | null;
  reportSource: "manual" | "postRepel";
  repelEventId?: string | null;
}

export interface DerivedHotspot {
  hotspotId: string;
  lat: number;
  lng: number;
  dangerLevel: DangerLevel;
  note: string;
}

export interface HotspotDocument {
  lat: number;
  lng: number;
  reportCount: number;
  dangerLevel: DangerLevel;
  lastReported: Timestamp;
  updatedAt: Timestamp;
  createdAt: Timestamp;
  areaRadiusMeters: number;
  note: string;
  latestBehavior: DogBehavior;
  latestSeverity: ReportSeverity;
  latestReportId: string;
}

export interface DuplicateCheckResult {
  isDuplicate: boolean;
  matchedReportId?: string;
}

export interface AggregationResult {
  status: AggregationStatus;
  derivedHotspotId?: string;
}

export function validateReportDocument(
  value: unknown,
): value is ReportDocument {
  if (!value || typeof value !== "object") {
    return false;
  }

  const report = value as Record<string, unknown>;

  return (
    typeof report.userId === "string" &&
    typeof report.lat === "number" &&
    typeof report.lng === "number" &&
    report.lat >= -90 &&
    report.lat <= 90 &&
    report.lng >= -180 &&
    report.lng <= 180 &&
    report.timestamp instanceof Timestamp &&
    (report.severity === "low" ||
      report.severity === "caution" ||
      report.severity === "high") &&
    (report.behavior === "calm" ||
      report.behavior === "barking" ||
      report.behavior === "chasing" ||
      report.behavior === "aggressive") &&
    typeof report.dogCount === "number" &&
    report.dogCount >= 1 &&
    report.dogCount <= 12 &&
    typeof report.anonymous === "boolean" &&
    (report.description === undefined ||
      report.description === null ||
      typeof report.description === "string") &&
    (report.photoUrl === undefined ||
      report.photoUrl === null ||
      typeof report.photoUrl === "string") &&
    (report.reportSource === "manual" || report.reportSource === "postRepel") &&
    (report.repelEventId === undefined ||
      report.repelEventId === null ||
      typeof report.repelEventId === "string")
  );
}

export function deriveHotspot(report: ReportDocument): DerivedHotspot {
  const latCell = Math.floor(report.lat / HOTSPOT_GRID_SIZE_DEGREES);
  const lngCell = Math.floor(report.lng / HOTSPOT_GRID_SIZE_DEGREES);

  return {
    hotspotId: `cell_${latCell}_${lngCell}`,
    lat: (latCell + 0.5) * HOTSPOT_GRID_SIZE_DEGREES,
    lng: (lngCell + 0.5) * HOTSPOT_GRID_SIZE_DEGREES,
    dangerLevel: report.severity === "high" ? "danger" : "caution",
    note:
      report.description && report.description.trim().length > 0
        ? report.description.trim()
        : `${report.dogCount} ${report.behavior} ${
            report.dogCount === 1 ? "dog" : "dogs"
          } reported by the community.`,
  };
}

export function buildAggregatedHotspot(params: {
  report: ReportDocument;
  reportId: string;
  derivedHotspot: DerivedHotspot;
  existingHotspot?: Partial<HotspotDocument> | undefined;
}): HotspotDocument {
  const { report, reportId, derivedHotspot, existingHotspot } = params;
  const currentCount = typeof existingHotspot?.reportCount === "number"
    ? existingHotspot.reportCount
    : 0;
  const nextCount = currentCount + 1;
  const existingDangerLevel = existingHotspot?.dangerLevel === "danger"
    ? "danger"
    : "caution";

  return {
    lat: derivedHotspot.lat,
    lng: derivedHotspot.lng,
    reportCount: nextCount,
    dangerLevel:
      existingDangerLevel === "danger" ||
        derivedHotspot.dangerLevel === "danger"
        ? "danger"
        : "caution",
    lastReported: report.timestamp,
    updatedAt: report.timestamp,
    createdAt:
      existingHotspot?.createdAt instanceof Timestamp
        ? existingHotspot.createdAt
        : report.timestamp,
    areaRadiusMeters: Math.min(
      HOTSPOT_MAX_RADIUS_METERS,
      HOTSPOT_BASE_RADIUS_METERS + Math.max(0, nextCount - 1) * 20,
    ),
    note: derivedHotspot.note,
    latestBehavior: report.behavior,
    latestSeverity: report.severity,
    latestReportId: reportId,
  };
}

export function isDuplicateReport(params: {
  reportId: string;
  report: ReportDocument;
  derivedHotspotId: string;
  candidates: Array<{ id: string; data: ReportDocument }>;
}): DuplicateCheckResult {
  const { reportId, report, derivedHotspotId, candidates } = params;

  for (const candidate of candidates) {
    if (candidate.id === reportId) {
      continue;
    }
    if (candidate.data.userId !== report.userId) {
      continue;
    }

    const candidateHotspotId = deriveHotspot(candidate.data).hotspotId;
    if (candidateHotspotId !== derivedHotspotId) {
      continue;
    }

    const ageDifference = Math.abs(
      report.timestamp.toMillis() - candidate.data.timestamp.toMillis(),
    );
    if (ageDifference <= DUPLICATE_WINDOW_MS) {
      return {
        isDuplicate: true,
        matchedReportId: candidate.id,
      };
    }
  }

  return { isDuplicate: false };
}

export function assertValidReport(
  value: unknown,
): ReportDocument {
  assert.ok(validateReportDocument(value), "Invalid report payload");
  return value;
}
