/**
 * Firebase Demo Data Setup Script
 * Uses Firebase REST API - no service account needed!
 * 
 * Run: node setup_firebase_rest.js
 */
const https = require('https');

const PROJECT_ID = 'smart-waste-collection-6a2f0';
const WEB_API_KEY = 'AIzaSyBvKTIUtyFGF5V7C0CpPrqjq5MfVAitniY'; // Web API key from main.dart

const DEMO_USERS = [
    {
        email: 'admin@smartwaste.com',
        password: 'Demo@123',
        role: 'admin',
        name: 'Demo Admin',
        phone: '9999900001',
    },
    {
        email: 'driver1@smartwaste.com',
        password: 'Demo@123',
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
        role: 'resident',
        name: 'Demo Resident',
        phone: '9999900003',
        address: '123 Main Street, Mumbai',
        ward: 'Ward A',
    },
];

function httpsPost(hostname, path, data, headers = {}) {
    return new Promise((resolve, reject) => {
        const body = JSON.stringify(data);
        const options = {
            hostname,
            path,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(body),
                ...headers,
            },
        };
        const req = https.request(options, (res) => {
            let responseData = '';
            res.on('data', (chunk) => (responseData += chunk));
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, body: JSON.parse(responseData) });
                } catch (e) {
                    resolve({ status: res.statusCode, body: responseData });
                }
            });
        });
        req.on('error', reject);
        req.write(body);
        req.end();
    });
}

function httpsRequest(hostname, path, method, data, headers = {}) {
    return new Promise((resolve, reject) => {
        const body = data ? JSON.stringify(data) : '';
        const options = {
            hostname,
            path,
            method,
            headers: {
                'Content-Type': 'application/json',
                ...(body ? { 'Content-Length': Buffer.byteLength(body) } : {}),
                ...headers,
            },
        };
        const req = https.request(options, (res) => {
            let responseData = '';
            res.on('data', (chunk) => (responseData += chunk));
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, body: JSON.parse(responseData) });
                } catch (e) {
                    resolve({ status: res.statusCode, body: responseData });
                }
            });
        });
        req.on('error', reject);
        if (body) req.write(body);
        req.end();
    });
}

async function signIn(email, password) {
    const result = await httpsPost(
        'identitytoolkit.googleapis.com',
        `/v1/accounts:signInWithPassword?key=${WEB_API_KEY}`,
        { email, password, returnSecureToken: true }
    );
    return result;
}

async function signUp(email, password) {
    const result = await httpsPost(
        'identitytoolkit.googleapis.com',
        `/v1/accounts:signUp?key=${WEB_API_KEY}`,
        { email, password, returnSecureToken: true }
    );
    return result;
}

async function writeFirestoreDoc(uid, data, idToken) {
    // Convert data to Firestore format
    const fields = {};
    for (const [key, value] of Object.entries(data)) {
        if (typeof value === 'string') {
            fields[key] = { stringValue: value };
        } else if (typeof value === 'number') {
            fields[key] = { integerValue: String(value) };
        } else if (typeof value === 'boolean') {
            fields[key] = { booleanValue: value };
        }
    }

    const result = await httpsRequest(
        'firestore.googleapis.com',
        `/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`,
        'PATCH',
        { fields },
        idToken ? { Authorization: `Bearer ${idToken}` } : {}
    );
    return result;
}

async function setup() {
    console.log('\n🚀 Smart Waste App - Firebase Setup\n');
    console.log('This script creates demo users via Firebase REST API.\n');

    for (const user of DEMO_USERS) {
        const { email, password, ...extraData } = user;
        console.log(`\n📧 Processing: ${email}`);

        // Try to sign in first (to get UID if user exists)
        let uid = null;
        let idToken = null;

        const signInResult = await signIn(email, password);
        if (signInResult.status === 200) {
            uid = signInResult.body.localId;
            idToken = signInResult.body.idToken;
            console.log(`  ✅ User exists. UID: ${uid}`);
        } else if (signInResult.body.error?.message === 'EMAIL_NOT_FOUND' ||
            signInResult.body.error?.message === 'INVALID_LOGIN_CREDENTIALS' ||
            signInResult.body.error?.message?.includes('TOO_MANY_ATTEMPTS')) {
            // Try signup
            console.log(`  👤 Creating new user...`);
            const signUpResult = await signUp(email, password);
            if (signUpResult.status === 200) {
                uid = signUpResult.body.localId;
                idToken = signUpResult.body.idToken;
                console.log(`  ✅ Created. UID: ${uid}`);
            } else {
                console.log(`  ❌ Failed signup: ${JSON.stringify(signUpResult.body.error)}`);
                // If user exists with wrong password, note it
                if (signUpResult.body.error?.message === 'EMAIL_EXISTS') {
                    console.log(`  ⚠️  User exists with different password. Please manually reset password to 'Demo@123' in Firebase Console.`);
                }
                continue;
            }
        } else {
            // Try to sign up (user might exist with wrong password)
            if (signInResult.body.error?.message === 'INVALID_PASSWORD') {
                console.log(`  ⚠️  User exists but password mismatch. Trying to sign up...`);
                const signUpResult = await signUp(email, password);
                if (signUpResult.body.error?.message === 'EMAIL_EXISTS') {
                    console.log(`  ❌ Cannot auto-fix password. You must manually go to Firebase Console > Authentication > Reset password for ${email} to 'Demo@123'.`);
                    continue;
                }
            } else {
                console.log(`  ❌ Unexpected error: ${JSON.stringify(signInResult.body.error)}`);
                continue;
            }
        }

        if (!uid) {
            console.log(`  ❌ Could not get UID for ${email}. Skipping Firestore write.`);
            continue;
        }

        // Write Firestore document
        const docData = { id: uid, email, ...extraData };
        const firestoreResult = await writeFirestoreDoc(uid, docData, idToken);
        if (firestoreResult.status === 200) {
            console.log(`  ✅ Firestore doc written for ${email} (role: ${extraData.role})`);
        } else {
            console.log(`  ❌ Firestore write failed (status: ${firestoreResult.status}): ${JSON.stringify(firestoreResult.body)}`);
        }
    }

    console.log('\n✨ Setup complete!\n');
    console.log('Demo Credentials:');
    console.log('  Admin:    admin@smartwaste.com     / Demo@123');
    console.log('  Driver:   driver1@smartwaste.com   / Demo@123');
    console.log('  Resident: resident1@smartwaste.com / Demo@123');
    console.log('\nOpen http://localhost:5001/ and use Quick Sign-in to test.\n');
}

setup().catch(console.error);
