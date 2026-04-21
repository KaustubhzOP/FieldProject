const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

/**
 * Configure Nodemailer with your SMTP provider
 * Best practice: Use Environment Variables for security
 */
function getTransporter() {
  const user = functions.config().email?.user;
  const pass = functions.config().email?.pass;

  if (!user || !pass) {
    console.warn('[System] EMAIL_CONFIG_MISSING: Using dummy credentials. Emails will fail in production.');
  }

  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: user || 'demo@smartwaste.com',
      pass: pass || 'demo-password',
    },
  });
}

/**
 * Trigger: Listens to any update in the 'complaints' collection
 */
exports.onComplaintUpdate = functions.firestore
  .document('complaints/{complaintId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const complaintId = context.params.complaintId;

    // 1. Core Logic: Detect Status Change
    const oldStatus = beforeData?.status;
    const newStatus = afterData?.status;
    const userId = afterData?.raisedBy;

    console.log(`[TRIGGER] Event for #${complaintId} | Transition: ${oldStatus} -> ${newStatus}`);

    if (oldStatus === newStatus) {
      console.log(`[SKIP] Status unchanged for #${complaintId}. No email required.`);
      return null;
    }

    // 2. Data Validation
    if (!userId) {
      console.error(`[CRITICAL] Missing 'raisedBy' field in complaint #${complaintId}. Cannot identify recipient.`);
      return null;
    }

    try {
      // 3. Fetch Recipient Data
      console.log(`[USER_FETCH] Searching for UID: ${userId}...`);
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        console.error(`[ERROR] User Profile NOT FOUND for UID: ${userId}. Abandoning notify.`);
        return null;
      }

      const userData = userDoc.data();
      const userEmail = userData.email;
      const userName = userData.name || 'Resident';

      if (!userEmail) {
        console.error(`[ERROR] User ${userId} has NO EMAIL address configured.`);
        return null;
      }

      console.log(`[USER_FOUND] Recipient: ${userName} <${userEmail}>`);

      // 4. Message Construction
      let message = '';
      let subject = `Update: Complaint #${complaintId} Status Changed`;

      switch (newStatus) {
        case 'in_progress':
          message = 'A garbage collection truck has been assigned to your complaint. Our team is now working on it.';
          break;
        case 'resolved':
          message = 'Great news! Your waste collection complaint has been successfully resolved. Thank you for your patience.';
          subject = `Resolved: Complaint #${complaintId}`;
          break;
        default:
          message = `The status of your complaint has been updated to: ${newStatus.toUpperCase()}.`;
      }

      const mailOptions = {
        from: '"Smart Waste" <noreply@smartwaste.com>',
        to: userEmail,
        subject: subject,
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
            <h2 style="color: #2563eb;">Complaint Update</h2>
            <p>Hello ${userName},</p>
            <p>Your complaint status has been updated to: <strong>${newStatus.toUpperCase()}</strong></p>
            <p style="background: #f9fafb; padding: 15px; border-left: 4px solid #2563eb;">${message}</p>
            <p style="font-size: 11px; color: #999;">Complaint ID: ${complaintId}</p>
          </div>
        `,
      };

      // 5. Secure Send Attempt
      console.log(`[SMTP_ATTEMPT] Sending to ${userEmail}...`);
      const transporter = getTransporter();
      await transporter.sendMail(mailOptions);
      
      console.log(`[SUCCESS] Email delivered for #${complaintId} to ${userEmail}`);
      return { success: true, timestamp: new Date().toISOString() };

    } catch (error) {
      console.error(`[SMTP_FAILURE] Failed to deliver for #${complaintId}. Error:`, error.message);
      if (error.code === 'EAUTH') {
        console.error('[AUTH_FAILED] Please verify your firebase functions:config:set email.user/pass credentials.');
      }
      return null;
    }
  });
