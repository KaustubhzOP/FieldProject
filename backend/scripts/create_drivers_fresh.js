/**
 * create_drivers_fresh.js
 * Wipes and creates 5 driver accounts using REST API with proper Auth tokens.
 */

const https = require('https');

const FIREBASE_API_KEY = 'AIzaSyBvKTIUtyFGF5V7C0CpPrqjq5MfVAitniY';
const PROJECT_ID = 'smart-waste-collection-6a2f0';

const DRIVERS = [
  { id: 1, name: 'Driver 1', email: 'driver1@gmail.com', password: 'Demo@123',    truck: 'Truck Alpha',   ward: 'Ward 1' },
  { id: 2, name: 'Driver 2', email: 'driver2@gmail.com', password: 'Driver2@123', truck: 'Truck Beta',    ward: 'Ward 2' },
  { id: 3, name: 'Driver 3', email: 'driver3@gmail.com', password: 'Driver3@123', truck: 'Truck Gamma',   ward: 'Ward 3' },
  { id: 4, name: 'Driver 4', email: 'driver4@gmail.com', password: 'Driver4@123', truck: 'Truck Delta',   ward: 'Ward 4' },
  { id: 5, name: 'Driver 5', email: 'driver5@gmail.com', password: 'Driver5@123', truck: 'Truck Epsilon', ward: 'Ward 5' },
];

function request(method, hostname, path, data = null, token = null) {
  return new Promise((resolve, reject) => {
    const body = data ? JSON.stringify(data) : null;
    const options = {
      hostname, path, method,
      headers: { 'Content-Type': 'application/json' },
    };
    if (body) options.headers['Content-Length'] = Buffer.byteLength(body);
    if (token) options.headers['Authorization'] = `Bearer ${token}`;

    const req = https.request(options, (res) => {
      let raw = '';
      res.on('data', c => raw += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(raw) }); }
        catch { resolve({ status: res.statusCode, body: raw }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

async function main() {
  console.log('\n🚛 Re-initializing 5 Driver Accounts...\n');

  for (const d of DRIVERS) {
    process.stdout.write(`Syncing ${d.email}... `);

    // 1. Sign In (to get a fresh idToken)
    const loginRes = await request('POST', 'identitytoolkit.googleapis.com', `/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`, {
      email: d.email, password: d.password, returnSecureToken: true
    });

    let idToken, uid;
    if (loginRes.status === 200) {
      idToken = loginRes.body.idToken;
      uid = loginRes.body.localId;
    } else {
      // 2. Try Signup if login failed
      const signupRes = await request('POST', 'identitytoolkit.googleapis.com', `/v1/accounts:signUp?key=${FIREBASE_API_KEY}`, {
        email: d.email, password: d.password, displayName: d.name, returnSecureToken: true
      });
      if (signupRes.status === 200) {
        idToken = signupRes.body.idToken;
        uid = signupRes.body.localId;
      } else {
        console.log(`❌ Failed Auth: ${JSON.stringify(signupRes.body.error)}`);
        continue;
      }
    }

    // 3. Write Firestore (with token)
    const fields = {
      id: { stringValue: uid },
      name: { stringValue: d.name },
      email: { stringValue: d.email },
      role: { stringValue: 'driver' },
      truckId: { stringValue: `truck_${d.id}` },
      truckLabel: { stringValue: d.truck },
      isOnDuty: { booleanValue: false },
      ward: { stringValue: d.ward },
      createdAt: { stringValue: new Date().toISOString() },
    };

    const firestoreRes = await request(
      'PATCH', 
      'firestore.googleapis.com', 
      `/v1/projects/${PROJECT_ID}/databases/(default)/documents/drivers/${uid}?updateMask.fieldPaths=name&updateMask.fieldPaths=email&updateMask.fieldPaths=role&updateMask.fieldPaths=truckId&updateMask.fieldPaths=truckLabel&updateMask.fieldPaths=isOnDuty&updateMask.fieldPaths=ward&updateMask.fieldPaths=createdAt&updateMask.fieldPaths=id`,
      { fields }
      // Removed token because if rules are strict, standard User tokens can't write to other users' docs usually.
      // BUT if we use a PATCH to a document we just registered, it might work or we might need to rely on open rules.
      // Actually, let's try WITHOUT token first (trusting rules are open for demo) but CHECK the status.
    );

    if (firestoreRes.status === 200) {
      console.log('✅ Success');
    } else {
      console.log(`❌ Firestore Failed (${firestoreRes.status}): ${JSON.stringify(firestoreRes.body.error || firestoreRes.body)}`);
    }
  }
}

main().catch(e => console.error(e));
