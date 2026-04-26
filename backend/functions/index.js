const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// ─────────────────────────────────────────────
//  SMTP Transport (Nodemailer via Gmail)
// ─────────────────────────────────────────────
function getTransporter() {
  const user = functions.config().email?.user || '2024.kaustubh.patil@ves.ac.in';
  const pass = functions.config().email?.pass || 'amgm ibwh fixb xrqc'; // Real creds from frontend

  return nodemailer.createTransport({
    service: 'gmail',
    auth: { user, pass },
  });
}

async function fetchUser(userId) {
  const doc = await admin.firestore().collection('users').doc(userId).get();
  return doc.exists ? doc.data() : null;
}

async function sendEmail({ to, subject, heading, bodyHtml }) {
  const transporter = getTransporter();
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #1e40af, #0ea5e9); padding: 28px 32px;">
        <h1 style="color: #ffffff; margin: 0; font-size: 20px;">♻️ Smart Waste Collection</h1>
        <p style="color: #bfdbfe; margin: 4px 0 0; font-size: 13px;">BMC Waste Management System</p>
      </div>
      <div style="padding: 32px;">
        <h2 style="color: #1e293b; margin: 0 0 16px;">${heading}</h2>
        ${bodyHtml}
        <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 24px 0;" />
        <p style="color: #94a3b8; font-size: 12px; margin: 0;">Automated notification. Do not reply.</p>
      </div>
    </div>
  `;

  try {
    await transporter.sendMail({
      from: '"Smart Waste BMC" <noreply@smartwaste.com>',
      to,
      subject,
      html,
    });
    console.log(`[Email] Sent to ${to}`);
  } catch (err) {
    console.error(`[Email] Error sending to ${to}:`, err);
  }
}

// ─────────────────────────────────────────────
//  TRIGGER: New complaint created
// ─────────────────────────────────────────────
exports.onComplaintCreated = functions.firestore
  .document('complaints/{complaintId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const complaintId = context.params.complaintId;
    const userId = data.raisedBy;

    try {
      const resident = await fetchUser(userId);
      if (resident && resident.email) {
        // 1. Email to Resident
        const bodyHtml = `<p>Your complaint <strong>#${complaintId.toUpperCase()}</strong> has been registered successfully.</p>`;
        await sendEmail({
          to: resident.email,
          subject: `Complaint Registered — #${complaintId.toUpperCase()}`,
          heading: '✅ Complaint Registered',
          bodyHtml,
        });
      }

      // 2. Alert all Admins (Email + Push)
      const adminsSnapshot = await admin.firestore().collection('users').where('role', '==', 'admin').get();
      const adminTokens = [];

      for (const adminDoc of adminsSnapshot.docs) {
        const adminData = adminDoc.data();
        if (adminData.email) {
          await sendEmail({
            to: adminData.email,
            subject: '🚨 New Complaint Alert',
            heading: 'New Complaint Filed',
            bodyHtml: `<p>Resident <strong>${resident?.name || 'User'}</strong> has filed a new complaint (#${complaintId.toUpperCase()}).</p>`,
          });
        }
        if (adminData.fcmToken) {
          adminTokens.push(adminData.fcmToken);
        }
      }

      if (adminTokens.length > 0) {
        const message = {
          notification: {
            title: '🚨 New Complaint Filed',
            body: `${resident?.name || 'A resident'} raised a new ${data.type || 'complaint'}.`,
          },
          data: {
            type: 'new_complaint',
            complaintId: complaintId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          tokens: adminTokens,
        };
        await admin.messaging().sendMulticast(message);
        console.log(`[FCM] Sent to ${adminTokens.length} admins`);
      }

    } catch (err) {
      console.error('[onComplaintCreated] Error:', err);
    }
  });

// ─────────────────────────────────────────────
//  TRIGGER: Complaint status updated
// ─────────────────────────────────────────────
exports.onComplaintUpdate = functions.firestore
  .document('complaints/{complaintId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const complaintId = context.params.complaintId;

    if (before.status === after.status) return null; // Status didn't change

    try {
      const resident = await fetchUser(after.raisedBy);
      if (!resident) return null;

      const statusMap = {
        'pending': 'Pending',
        'in_progress': 'In Progress',
        'resolved': 'Resolved',
        'rejected': 'Rejected',
      };

      const newStatusLabel = statusMap[after.status] || after.status;

      // 1. Email to Resident
      if (resident.email) {
        await sendEmail({
          to: resident.email,
          subject: `Complaint Status Update — #${complaintId.toUpperCase()}`,
          heading: 'Complaint Updated',
          bodyHtml: `<p>The status of your complaint <strong>#${complaintId.toUpperCase()}</strong> has changed to <strong>${newStatusLabel}</strong>.</p>`,
        });
      }

      // 2. FCM Push to Resident
      if (resident.fcmToken) {
        const message = {
          notification: {
            title: '📋 Complaint Status Updated',
            body: `Your complaint #${complaintId.toUpperCase()} is now ${newStatusLabel}.`,
          },
          data: {
            type: 'status_update',
            complaintId: complaintId,
            status: after.status,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          token: resident.fcmToken,
        };
        await admin.messaging().send(message);
        console.log(`[FCM] Sent status update to ${after.raisedBy}`);
      }

    } catch (err) {
      console.error('[onComplaintUpdate] Error:', err);
    }
  });

// ─────────────────────────────────────────────
//  TRIGGER: Truck arrival
// ─────────────────────────────────────────────
exports.onTruckArrival = functions.firestore
  .document('arrivals/{arrivalId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    try {
      const resident = await fetchUser(data.residentId);
      if (resident && resident.fcmToken) {
        const message = {
          notification: {
            title: 'Truck Arrival Alert 🚛',
            body: 'A garbage collection truck has arrived near your location.',
          },
          data: {
            type: 'truck_arrival',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          token: resident.fcmToken,
        };
        await admin.messaging().send(message);
      }
    } catch (err) {
      console.error('[onTruckArrival] Error:', err);
    }
  });
