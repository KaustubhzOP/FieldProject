const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'smart-waste-collection-6a2f0',
});

const auth = admin.auth();
const db = admin.firestore();

const drivers = [
  { id: 1, name: 'Raj Kumar',    email: 'driver1@smartwaste.com', password: 'Demo@123',    truck: 'Truck Alpha (WB-01)' },
  { id: 2, name: 'Priya Singh',  email: 'driver2@smartwaste.com', password: 'Driver2@123', truck: 'Truck Beta  (WB-02)' },
  { id: 3, name: 'Amit Sharma',  email: 'driver3@smartwaste.com', password: 'Driver3@123', truck: 'Truck Gamma (WB-03)' },
  { id: 4, name: 'Sunita Patel', email: 'driver4@smartwaste.com', password: 'Driver4@123', truck: 'Truck Delta (WB-04)' },
  { id: 5, name: 'Vikram Reddy', email: 'driver5@smartwaste.com', password: 'Driver5@123', truck: 'Truck Epsilon (WB-05)' },
];

async function createOrUpdateDriver(driver) {
  let uid;

  // Try to get existing user
  try {
    const existing = await auth.getUserByEmail(driver.email);
    uid = existing.uid;
    console.log(`✔ Exists: ${driver.email} (UID: ${uid})`);
    // Update password in case it changed
    await auth.updateUser(uid, { password: driver.password, displayName: driver.name });
  } catch (_) {
    // Create new user
    const created = await auth.createUser({
      email: driver.email,
      password: driver.password,
      displayName: driver.name,
      emailVerified: true,
    });
    uid = created.uid;
    console.log(`✅ Created: ${driver.email} (UID: ${uid})`);
  }

  // Write / update Firestore user document
  await db.collection('users').doc(uid).set({
    id: uid,
    name: driver.name,
    email: driver.email,
    role: 'driver',
    truckId: `truck_${driver.id}`,
    truckLabel: driver.truck,
    isOnDuty: false,
    ward: `Ward ${driver.id}`,
    createdAt: new Date().toISOString(),
  }, { merge: true });

  // Write / update Firestore drivers document
  await db.collection('drivers').doc(uid).set({
    id: uid,
    name: driver.name,
    email: driver.email,
    truckId: `truck_${driver.id}`,
    truckLabel: driver.truck,
    isOnDuty: false,
    currentLocation: null,
    ward: `Ward ${driver.id}`,
    completedRoutes: 0,
    rating: 4.5,
  }, { merge: true });

  return { ...driver, uid };
}

async function main() {
  console.log('\n🚛 Creating 5 Driver Accounts...\n');
  const results = [];
  for (const d of drivers) {
    const r = await createOrUpdateDriver(d);
    results.push(r);
  }

  console.log('\n════════════════════════════════════════');
  console.log('   ALL DRIVER ACCOUNTS READY!');
  console.log('════════════════════════════════════════');
  for (const r of results) {
    console.log(`\n🚛 Driver ${r.id} — ${r.name}`);
    console.log(`   Email    : ${r.email}`);
    console.log(`   Password : ${r.password}`);
    console.log(`   Truck    : ${r.truck}`);
    console.log(`   UID      : ${r.uid}`);
  }
  console.log('\n════════════════════════════════════════\n');
  process.exit(0);
}

main().catch(e => { console.error('❌ Error:', e); process.exit(1); });
