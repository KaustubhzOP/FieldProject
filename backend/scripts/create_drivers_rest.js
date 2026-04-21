/**
 * create_drivers_rest.js
 * Creates 5 driver accounts using Firebase REST API + Firestore REST API
 * No service account key needed — uses the app's web API key.
 * Run: node create_drivers_rest.js
 */

const https = require('https');

const FIREBASE_API_KEY = 'AIzaSyBvKTIUtyFGF5V7C0CpPrqjq5MfVAitniY';
const PROJECT_ID = 'smart-waste-collection-6a2f0';

const DRIVERS = [
  { id: 1, name: 'Raj Kumar',    email: 'driver1@smartwaste.com', password: 'Demo@123',    truck: 'Truck Alpha',   ward: 'Ward 1' },
  { id: 2, name: 'Priya Singh',  email: 'driver2@smartwaste.com', password: 'Driver2@123', truck: 'Truck Beta',    ward: 'Ward 2' },
  { id: 3, name: 'Amit Sharma',  email: 'driver3@smartwaste.com', password: 'Driver3@123', truck: 'Truck Gamma',   ward: 'Ward 3' },
  { id: 4, name: 'Sunita Patel', email: 'driver4@smartwaste.com', password: 'Driver4@123', truck: 'Truck Delta',   ward: 'Ward 4' },
  { id: 5, name: 'Vikram Reddy', email: 'driver5@smartwaste.com', password: 'Driver5@123', truck: 'Truck Epsilon', ward: 'Ward 5' },
];

function post(hostname, path, data) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(data);
    const req = https.request({
      hostname, path, method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    }, (res) => {
      let raw = '';
      res.on('data', c => raw += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(raw) }); }
        catch { resolve({ status: res.statusCode, body: raw }); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function patch(hostname, path, data) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(data);
    const req = https.request({
      hostname, path, method: 'PATCH',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    }, (res) => {
      let raw = '';
      res.on('data', c => raw += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(raw) }); }
        catch { resolve({ status: res.statusCode, body: raw }); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// Sign up a user via Firebase Auth REST API
async function signUp(email, password, displayName) {
  const res = await post(
    'identitytoolkit.googleapis.com',
    `/v1/accounts:signUp?key=${FIREBASE_API_KEY}`,
    { email, password, displayName, returnSecureToken: false }
  );
  return res;
}

// Write a Firestore doc using REST (no auth needed if rules allow — otherwise skip)
async function writeFirestore(collection, docId, fields, idToken) {
  const firestoreFields = {};
  for (const [k, v] of Object.entries(fields)) {
    if (typeof v === 'string') firestoreFields[k] = { stringValue: v };
    else if (typeof v === 'boolean') firestoreFields[k] = { booleanValue: v };
    else if (typeof v === 'number') firestoreFields[k] = { integerValue: String(v) };
    else if (v === null) firestoreFields[k] = { nullValue: null };
  }

  const res = await patch(
    'firestore.googleapis.com',
    `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}`,
    { fields: firestoreFields }
  );
  return res;
}

async function main() {
  console.log('\n🚛  Creating 5 Driver Accounts via Firebase REST API...\n');

  const results = [];

  for (const d of DRIVERS) {
    process.stdout.write(`Creating ${d.email}... `);

    const authRes = await signUp(d.email, d.password, d.name);

    if (authRes.status === 200 && authRes.body.localId) {
      const uid = authRes.body.localId;
      console.log(`✅ Created (UID: ${uid})`);

      // Write to users collection
      await writeFirestore('users', uid, {
        id: uid, name: d.name, email: d.email, role: 'driver',
        truckId: `truck_${d.id}`, truckLabel: d.truck,
        isOnDuty: false, ward: d.ward,
        createdAt: new Date().toISOString(),
      });

      // Write to drivers collection
      await writeFirestore('drivers', uid, {
        id: uid, name: d.name, email: d.email,
        truckId: `truck_${d.id}`, truckLabel: d.truck,
        isOnDuty: false, ward: d.ward,
        completedRoutes: 0,
      });

      results.push({ ...d, uid, status: 'created' });

    } else if (authRes.body.error?.message === 'EMAIL_EXISTS') {
      console.log('⚠️  Already exists (account intact)');
      results.push({ ...d, uid: 'existing', status: 'exists' });

    } else {
      console.log(`❌ Failed: ${JSON.stringify(authRes.body.error || authRes.body)}`);
      results.push({ ...d, uid: '?', status: 'failed' });
    }
  }

  console.log('\n════════════════════════════════════════════════════════');
  console.log('  ALL DRIVER ACCOUNTS — LOGIN CREDENTIALS');
  console.log('════════════════════════════════════════════════════════');
  for (const r of results) {
    console.log(`\n  🚛 Driver ${r.id}: ${r.name}  [${r.truck}]`);
    console.log(`     Email    → ${r.email}`);
    console.log(`     Password → ${r.password}`);
    console.log(`     Status   → ${r.status}`);
  }
  console.log('\n════════════════════════════════════════════════════════\n');
}

main().catch(e => { console.error('Error:', e); process.exit(1); });
