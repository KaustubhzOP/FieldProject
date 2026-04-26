const admin = require('firebase-admin');
const serviceAccount = require('../../frontend/assets/smart-waste-collection-6a2f0-firebase-adminsdk-fbsvc-04712bc14c.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

const email = 'arnavkale83@gmail.com';
const password = '12345678';
const driverName = 'Arnav Kale';

async function createDriver() {
    try {
        // 1. Create in Firebase Auth (or fetch if already exists)
        let userRecord;
        try {
            userRecord = await auth.createUser({ email, password, displayName: driverName });
            console.log(`✅ Auth user created: ${userRecord.uid}`);
        } catch (err) {
            if (err.code === 'auth/email-already-exists') {
                userRecord = await auth.getUserByEmail(email);
                await auth.updateUser(userRecord.uid, { password }); // Ensure password is set
                console.log(`ℹ️  Auth user already exists (password updated): ${userRecord.uid}`);
            } else {
                throw err;
            }
        }

        const uid = userRecord.uid;

        // 2. Set custom claim as driver
        await auth.setCustomUserClaims(uid, { role: 'driver' });
        console.log(`✅ Role claim set to 'driver'`);

        // 3. Create Firestore 'drivers' document
        await db.collection('drivers').doc(uid).set({
            id: uid,
            name: driverName,
            email: email,
            role: 'driver',
            isOnDuty: false,
            ward: 'Ward A',
            vehicleNumber: 'MH-XX-0001',
            liveLocation: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        console.log(`✅ 'drivers' Firestore document created`);

        // 4. Also upsert into 'users' collection (for login routing)
        await db.collection('users').doc(uid).set({
            id: uid,
            name: driverName,
            email: email,
            role: 'driver',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        console.log(`✅ 'users' Firestore document created`);

        console.log('\n🎉 Driver account is ready!');
        console.log(`   Email:    ${email}`);
        console.log(`   Password: ${password}`);
        console.log(`   UID:      ${uid}`);
    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        process.exit(0);
    }
}

createDriver();
