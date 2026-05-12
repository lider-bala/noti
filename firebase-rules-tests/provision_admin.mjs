import admin from 'firebase-admin';

const projectId = process.env.FIREBASE_PROJECT_ID || 'noti-c3136';
const schoolId = process.env.SCHOOL_ID || 'default';
const email = process.env.ADMIN_EMAIL || 'admin@noti.kg';
const password = process.env.ADMIN_PASSWORD || 'admin123';
const displayName = process.env.ADMIN_NAME || 'Bootstrap Admin';
const phoneNumber = process.env.ADMIN_PHONE || '+996555000444';
const preferredUid = process.env.ADMIN_UID || 'admin-bootstrap';

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId,
});

const auth = admin.auth();
const firestore = admin.firestore();

async function ensureUser() {
  try {
    return await auth.getUser(preferredUid);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }
  }

  try {
    return await auth.getUserByEmail(email);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }
  }

  return auth.createUser({
    uid: preferredUid,
    email,
    password,
    displayName,
    emailVerified: true,
  });
}

const user = await ensureUser();

await auth.updateUser(user.uid, {
  email,
  password,
  displayName,
  emailVerified: true,
});

await auth.setCustomUserClaims(user.uid, {
  role: 'admin',
  superAdmin: true,
});

await firestore
  .collection('schools')
  .doc(schoolId)
  .collection('accounts')
  .doc(user.uid)
  .set(
    {
      id: user.uid,
      fullName: displayName,
      email,
      phone: phoneNumber,
      role: 'admin',
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

console.log(`Admin ready: ${email} / ${password}`);
console.log(`uid=${user.uid}, project=${projectId}, school=${schoolId}`);
