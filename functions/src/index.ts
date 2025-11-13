import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

admin.initializeApp();
const db = admin.firestore();
const now = () => admin.firestore.Timestamp.now();

type BookingStatus = "pending"|"paid"|"accepted"|"in_progress"|"completed"|"cancelled";

// NOTE: These functions are NOT deployed on Spark plan.
// All booking logic is handled client-side. See lib/data/repositories/booking_repository.dart

// Set immutable snapshot + deadline at create (no scheduler needed)
export const onBookingCreate = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap: any) => {
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
  .onWrite(async (change: any) => {
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
  .onUpdate(async (change: any) => {
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

// Send push notification to student when tutor accepts/rejects booking
export const notifyBookingStatusChange = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change: any) => {
    const before = change.before.data() as any;
    const after = change.after.data() as any;

    // Only trigger on status change to accepted or cancelled
    if (before.status === after.status) return;
    
    const newStatus = after.status as BookingStatus;
    if (newStatus !== "accepted" && newStatus !== "cancelled") return;

    const studentId = after.studentId;
    const tutorName = after.tutorName || "A tutor";
    const subject = after.subject || "your booking";

    try {
      // Get student's FCM tokens
      const studentDoc = await db.doc(`users/${studentId}`).get();
      const studentData = studentDoc.data();
      const fcmTokens = studentData?.fcmTokens || [];

      if (fcmTokens.length === 0) {
        console.log(`⚠️ No FCM tokens found for student ${studentId}`);
        return;
      }

      // Prepare notification based on status
      let title = "";
      let body = "";
      let icon = "";

      if (newStatus === "accepted") {
        title = "✅ Booking Accepted!";
        body = `${tutorName} has accepted your ${subject} booking.`;
        icon = "✅";
      } else if (newStatus === "cancelled") {
        // Check if this was a tutor rejection or auto-cancellation
        const isTutorRejection = after.cancelledAt && before.status === "paid";
        if (isTutorRejection) {
          title = "❌ Booking Declined";
          body = `${tutorName} has declined your ${subject} booking.`;
          icon = "❌";
        } else {
          title = "⏰ Booking Cancelled";
          body = `Your booking with ${tutorName} was cancelled.`;
          icon = "⏰";
        }
      }

      // Send notification to all student's devices
      const messages = fcmTokens.map((token: string) => ({
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "booking_status_change",
          bookingId: change.after.id,
          status: newStatus,
          tutorName: tutorName,
          subject: subject,
        },
        android: {
          notification: {
            icon: icon,
            color: newStatus === "accepted" ? "#4CAF50" : "#FF9800",
            channelId: "bookings",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      }));

      // Send notifications
      const responses = await admin.messaging().sendEach(messages);
      
      let successCount = 0;
      let failureCount = 0;
      responses.responses.forEach((response, idx) => {
        if (response.success) {
          successCount++;
        } else {
          failureCount++;
          console.error(`Failed to send to token ${fcmTokens[idx]}: ${response.error}`);
        }
      });

      console.log(`✅ Notifications sent: ${successCount} success, ${failureCount} failed`);
    } catch (error) {
      console.error(`❌ Error sending notification for booking ${change.after.id}:`, error);
    }
  });
