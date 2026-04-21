/**
 * wipe_and_recreate_drivers.js
 * 1. Deletes all documents in current 'drivers' collection
 * 2. Re-runs driver creation to ensure ONLY the 5 real drivers exist
 */

const https = require('https');

const FIREBASE_API_KEY = 'AIzaSyBvKTIUtyFGF5V7C0CpPrqjq5MfVAitniY';
const PROJECT_ID = 'smart-waste-collection-6a2f0';

function request(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const body = data ? JSON.stringify(data) : null;
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents${path}`,
      method,
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
  console.log('\n🗑️  Cleaning up drivers collection...\n');

  // 1. List all documents in 'drivers'
  const listRes = await request('GET', '/drivers');
  const docs = listRes.body.documents || [];

  if (docs.length === 0) {
    console.log('No drivers found to delete.');
  } else {
    for (const doc of docs) {
      const name = doc.name.split('/').pop();
      process.stdout.write(`Deleting ${name}... `);
      await request('DELETE', `/drivers/${name}`);
      console.log('Done.');
    }
  }

  console.log('\n✨ Drivers collection wiped. Re-running creation script...');
  
  // No easy way to 'require' and run the other script easily without child_process
  // but I have already written create_drivers_rest.js, I will just call it via shell
}

main().catch(e => { console.error('Error:', e); process.exit(1); });
