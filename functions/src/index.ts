import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger, setGlobalOptions } from "firebase-functions/v2";
import {
  buildAggregatedHotspot,
  deriveHotspot,
  isDuplicateReport,
  validateReportDocument,
  type ReportDocument,
} from "./reportAggregation.js";

initializeApp();
setGlobalOptions({ maxInstances: 10 });

export const aggregateReportHotspot = onDocumentCreated(
  "reports/{reportId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const db = getFirestore();
    const reportId = event.params.reportId;
    const rawData = snapshot.data();

    if (!validateReportDocument(rawData)) {
      await snapshot.ref.set(
        {
          aggregationStatus: "invalid",
          aggregatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      logger.warn("Invalid report payload ignored", { reportId });
      return;
    }

    const report = rawData as ReportDocument;
    const derivedHotspot = deriveHotspot(report);
    const recentReports = await db
      .collection("reports")
      .where("userId", "==", report.userId)
      .where(
        "timestamp",
        ">=",
        Timestamp.fromMillis(report.timestamp.toMillis() - 15 * 60 * 1000),
      )
      .orderBy("timestamp", "desc")
      .limit(20)
      .get();

    const duplicateResult = isDuplicateReport({
      reportId,
      report,
      derivedHotspotId: derivedHotspot.hotspotId,
      candidates: recentReports.docs
        .map((doc) => ({ id: doc.id, data: doc.data() }))
        .filter((candidate): candidate is { id: string; data: ReportDocument } =>
          validateReportDocument(candidate.data),
        ),
    });

    if (duplicateResult.isDuplicate) {
      await snapshot.ref.set(
        {
          aggregationStatus: "duplicate",
          aggregatedAt: FieldValue.serverTimestamp(),
          derivedHotspotId: derivedHotspot.hotspotId,
        },
        { merge: true },
      );
      logger.info("Duplicate report suppressed", {
        reportId,
        matchedReportId: duplicateResult.matchedReportId,
        hotspotId: derivedHotspot.hotspotId,
      });
      return;
    }

    const hotspotRef = db.collection("hotspots").doc(derivedHotspot.hotspotId);
    await db.runTransaction(async (transaction) => {
      const hotspotSnapshot = await transaction.get(hotspotRef);
      const mergedHotspot = buildAggregatedHotspot({
        report,
        reportId,
        derivedHotspot,
        existingHotspot: hotspotSnapshot.exists
          ? hotspotSnapshot.data()
          : undefined,
      });

      transaction.set(hotspotRef, mergedHotspot, { merge: true });
      transaction.set(
        snapshot.ref,
        {
          aggregationStatus: "aggregated",
          aggregatedAt: FieldValue.serverTimestamp(),
          derivedHotspotId: derivedHotspot.hotspotId,
        },
        { merge: true },
      );
    });
  },
);
