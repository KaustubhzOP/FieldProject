/**
 * update_driver_passwords.js
 * Updates passwords for all 5 drivers to '123456'.
 */

const https = require('https');

const FIREBASE_API_KEY = 'AIzaSyBvKTIUtyFGF5V7C0CpPrqjq5MfVAitniY';
const PROJECT_ID = 'smart-waste-collection-6a2f0';

const DRIVERS = [
  'driver1@gmail.com',
  'driver2@gmail.com',
  'driver3@gmail.com',
  'driver4@gmail.com',
  'driver5@gmail.com'
];

function request(method, hostname, path, data = null) {
  return new Promise((resolve, reject) => {
    const body = data ? JSON.stringify(data) : null;
    const options = {
      hostname, path, method,
      headers: { 'Content-Type': 'application/json' },
    };
    if (body) options.headers['Content-Length'] = Buffer.byteLength(body);

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
  console.log('\n🔐 Updating Passwords to "123456" for 5 Drivers...\n');

  for (const email of DRIVERS) {
    process.stdout.write(`Updating ${email}... `);

    // 1. We need to get the UID first. The easiest way via REST is to try creating (it fails but returns email exists)
    // or just use the signUp endpoint which also returns the idToken for existing users in some cases? 
    // Actually, identitytoolkit v1 accounts:signUp with an existing email returns an error.
    
    // Better: We try to log in with ANY password (just to get the error) -> wait, it doesn't return UID.
    // Okay, I'll use the 'signUp' endpoint to ensure the account exists and get the UID if it's new.
    // If it exists, I'll log in with the OLD known password if I can, OR I'll assume it exists.
    
    // Actually, I'll use the 'signIn' to get the idToken for the ones I just created (Demo@123 / DriverN@123).
    // If that fails, I'll just skip or assume it's already 123456.

    const oldPasswords = ['Demo@123', 'Driver2@123', 'Driver3@123', 'Driver4@123', 'Driver5@123', '123456'];
    let idToken = null;

    for (const pw of oldPasswords) {
      const loginRes = await request('POST', 'identitytoolkit.googleapis.com', `/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`, {
        email, password: pw, returnSecureToken: true
      });
      if (loginRes.status === 200) {
        idToken = loginRes.body.idToken;
        break;
      }
    }

    if (!idToken) {
       // Try signup if it doesn't exist at all
       const signupRes = await request('POST', 'identitytoolkit.googleapis.com', `/v1/accounts:signUp?key=${FIREBASE_API_KEY}`, {
          email, password: '123456', returnSecureToken: true
       });
       if (signupRes.status === 200) {
          console.log('✅ Created fresh');
          continue;
       } else {
          console.log('❌ Failed to access account');
          continue;
       }
    }

    // 2. Update password using the idToken
    const updateRes = await request('POST', 'identitytoolkit.googleapis.com', `/v1/accounts:update?key=${FIREBASE_API_KEY}`, {
      idToken,
      password: '123456',
      returnSecureToken: true
    });

    if (updateRes.status === 200) {
      console.log('✅ Updated to 123456');
    } else {
      console.log(`❌ Update Failed: ${JSON.stringify(updateRes.body.error)}`);
    }
  }
}

main().catch(e => console.error(e));
