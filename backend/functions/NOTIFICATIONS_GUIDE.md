# Backend Email Notifications Guide

This guide explains how to configure and deploy the automated email notification system.

## 1. Prerequisites
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project initialized with Cloud Functions
- A Google/SMTP account for sending emails

## 2. Configuration
The system uses `nodemailer` and requires SMTP credentials. For production, store these securely using Firebase functions config:

```bash
# Set email credentials
firebase functions:config:set email.user="your-email@gmail.com" email.pass="your-app-password"

# Verify configuration
firebase functions:config:get
```

*Note: If using Gmail, you must generate an **App Password** from your Google Account security settings.*

## 3. Deployment
Navigate to the `backend` folder and deploy:

```bash
# Deploy only functions
firebase deploy --only functions
```

## 4. Trigger Logic
The function `onComplaintUpdate` monitors the `complaints` collection.
- It triggers only on code updates (Status Change).
- It fetches the User Document to get the email.
- It sends a styled HTML email using `nodemailer`.

## 5. Local Testing
To test logic locally before deployment:
1. Run `firebase emulators:start`
2. Update a complaint status in the Firestore emulator.
3. Check the console logs for "Email sent" confirmation.
