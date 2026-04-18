/**
 * Firebase Demo Data Setup Script
 * Run: node setup_firebase.js
 * Requires: GOOGLE_APPLICATION_CREDENTIALS env var pointing to service account JSON
 */
const admin = require('firebase-admin');

// Initialize using application default credentials or service account
let app;
try {
  app = admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'smart-waste-collection-6a2f0',
  });
} catch (e) {
  console.error('Failed to initialize with application default credentials:', e.message);
  process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

const DEMO_USERS = [
  {
    email: 'admin@smartwaste.com',
    password: 'Demo@123',
    displayName: 'Demo Admin',
    role: 'admin',
    name: 'Demo Admin',
    phone: '9999900001',
  },
  {
    email: 'driver1@smartwaste.com',
    password: 'Demo@123',
    displayName: 'Demo Driver',
    role: 'driver',
    name: 'Demo Driver',
    phone: '9999900002',
    status: 'on_duty',
    ward: 'Ward A',
    vehicleNumber: 'MH-01-AB-1234',
  },
  {
    email: 'resident1@smartwaste.com',
    password: 'Demo@123',
    displayName: 'Demo Resident',
    role: 'resident',
    name: 'Demo Resident',
    phone: '9999900003',
    address: '123 Main Street, Mumbai',
    ward: 'Ward A',
  },
];

async function deleteUserByEmail(email) {
  try {
    const user = await auth.getUserByEmail(email);
    await auth.deleteUser(user.uid);
    console.log(`Deleted existing user: ${email} (UID: ${user.uid})`);
    return user.uid;
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      console.log(`User not found, will create fresh: ${email}`);
      return null;
    }
    throw e;
  }
}

async function setupUsers() {
  console.log('\n🚀 Starting Firebase Demo Data Setup...\n');

  for (const userData of DEMO_USERS) {
    const { email, password, displayName, role, ...firestoreExtra } = userData;

    // Delete existing user first to ensure clean state
    await deleteUserByEmail(email);

    // Create the auth user
    const userRecord = await auth.createUser({
      email,
      password,
      displayName,
      emailVerified: true,
    });

    const uid = userRecord.uid;
    console.log(`✅ Created Auth user: ${email} (UID: ${uid})`);

    // Create/overwrite Firestore document
    const docData = {
      id: uid,
      email,
      name: displayName,
      role,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      ...firestoreExtra,
    };

    await db.collection('users').doc(uid).set(docData);
    console.log(`✅ Created Firestore doc for: ${email} | Role: ${role}`);
  }

  console.log('\n🎉 Setup complete! All demo users created.\n');
  console.log('Demo Credentials:');
  console.log('  Admin:    admin@smartwaste.com    / Demo@123');
  console.log('  Driver:   driver1@smartwaste.com  / Demo@123');
  console.log('  Resident: resident1@smartwaste.com / Demo@123');
  process.exit(0);
}

setupUsers().catch((err) => {
  console.error('\n❌ Error:', err);
  process.exit(1);
});
