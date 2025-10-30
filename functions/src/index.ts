import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

admin.initializeApp();
const db = admin.firestore();
const now = () => admin.firestore.Timestamp.now();

type BookingStatus = "pending"|"paid"|"accepted"|"in_progress"|"completed"|"cancelled";

// Set immutable snapshot + deadline at create (no scheduler needed)
export const onBookingCreate = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot) => {
    const data = snap.data() as any;
    const tutor = (await db.doc(`tutorProfiles/${data.tutorId}`).get()).data() || {};

    const acceptDeadline = admin.firestore.Timestamp.fromMillis(
      now().toMillis() + 15 * 60 * 1000
    );

    await snap.ref.set({
      tutorName: tutor.displayName ?? data.tutorName ?? "",
      hourlyRate: tutor.hourlyRate ?? data.hourlyRate ?? 0,
      subject: data.subject,
      minutes: data.minutes,
      status: "pending",
      createdAt: data.createdAt ?? now(),
      acceptDeadline
    }, { merge: true });
  });

// Guard illegal state jumps + auto-cancel if someone writes after deadline
export const guardBookingState = functions.firestore
  .document("bookings/{bookingId}")
  .onWrite(async (
    change: functions.Change<functions.firestore.DocumentSnapshot>
  ) => {
    if (!change.before.exists || !change.after.exists) return;
    const before = change.before.data() as any;
    const after = change.after.data() as any;

    const allowed: Record<BookingStatus, BookingStatus[]> = {
      pending: ["paid","cancelled"],
      paid: ["accepted","cancelled"],
      accepted: ["in_progress","cancelled"],
      in_progress: ["completed","cancelled"],
      completed: [],
      cancelled: []
    };

    const from: BookingStatus = before.status;
    const to: BookingStatus = after.status;

    // Auto-cancel if deadline passed and still not accepted
    if (["pending","paid"].includes(after.status)
        && after.acceptDeadline && after.acceptDeadline.toMillis() < now().toMillis()) {
      await change.after.ref.set({ status: "cancelled", cancelledAt: now() }, { merge: true });
      return;
    }

    if (!allowed[from].includes(to)) {
      await change.after.ref.set({ status: from }, { merge: true });
    }
  });

// On "paid" set/refresh acceptDeadline (kept on Spark)
export const onBookingPaid = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (
    change: functions.Change<functions.firestore.DocumentSnapshot>
  ) => {
    const before = change.before.data() as any;
    const after = change.after.data() as any;
    if (before.status !== "paid" && after.status === "paid") {
      await change.after.ref.set({
        acceptDeadline: admin.firestore.Timestamp.fromMillis(
          now().toMillis() + 15 * 60 * 1000
        )
      }, { merge: true });
    }
  });
