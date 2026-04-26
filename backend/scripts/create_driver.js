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
        let userRecord;
        try {
            userRecord = await auth.createUser({ email, password, displayName: driverName });
            console.log('✅ Auth user created: ' + userRecord.uid);
        } catch (err) {
            if (err.code === 'auth/email-already-exists') {
                userRecord = await auth.getUserByEmail(email);
                await auth.updateUser(userRecord.uid, { password });
                console.log('ℹ️  User already exists (password updated): ' + userRecord.uid);
            } else {
                throw err;
            }
        }

        const uid = userRecord.uid;
        await auth.setCustomUserClaims(uid, { role: 'driver' });
        console.log('✅ Role claim set to driver');

        await db.collection('drivers').doc(uid).set({
            id: uid, name: driverName, email: email, role: 'driver',
            isOnDuty: false, ward: 'Ward A', vehicleNumber: 'MH-XX-0001',
            liveLocation: null, createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        console.log('✅ drivers collection document created');

        await db.collection('users').doc(uid).set({
            id: uid, name: driverName, email: email, role: 'driver',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        console.log('✅ users collection document created');

        console.log('\n🎉 Done! Driver account ready:');
        console.log('   Email:    ' + email);
        console.log('   Password: ' + password);
        console.log('   UID:      ' + uid);
    } catch (err) {
        console.error('❌ Error:', err.message);
    } finally {
        process.exit(0);
    }
}

createDriver();
