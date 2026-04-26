const admin = require('firebase-admin');
const serviceAccount = require('../frontend/assets/smart-waste-collection-6a2f0-firebase-adminsdk-fbsvc-04712bc14c.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();

const EMAIL = '2024.kaustubh.patil@ves.ac.in';
const PASSWORD = '12345678';
const NAME = 'Kaustubh Patil';
const PHONE = '';

async function createAdmin() {
    try {
        // 1. Create Firebase Auth account
        let userRecord;
        try {
            userRecord = await auth.createUser({
                email: EMAIL,
                password: PASSWORD,
                displayName: NAME,
            });
            console.log('✅ Firebase Auth account created:', userRecord.uid);
        } catch (err) {
            if (err.code === 'auth/email-already-exists') {
                userRecord = await auth.getUserByEmail(EMAIL);
                console.log('ℹ️  Auth account already exists:', userRecord.uid);
                // Update password to be sure
                await auth.updateUser(userRecord.uid, { password: PASSWORD });
                console.log('🔑 Password updated');
            } else {
                throw err;
            }
        }

        // 2. Create/update Firestore user document
        await db.collection('users').doc(userRecord.uid).set({
            id: userRecord.uid,
            name: NAME,
            email: EMAIL,
            phone: PHONE,
            role: 'admin',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        console.log('✅ Firestore admin document created/updated');
        console.log('');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('Admin account ready!');
        console.log('Email   :', EMAIL);
        console.log('Password:', PASSWORD);
        console.log('Role    : admin');
        console.log('UID     :', userRecord.uid);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        process.exit(0);
    } catch (err) {
        console.error('❌ Error:', err.message);
        process.exit(1);
    }
}

createAdmin();
