const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "noti-c3136",
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('Noti KG Security Rules', () => {



  it('should DENY admin from creating account with superAdmin=true', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('schools/school1/accounts/admin_uid').set({ status: 'active', role: 'admin' });
    });
    const db = testEnv.authenticatedContext('admin_uid', { role: 'admin' }).firestore();

    await assertFails(db.doc('schools/school1/accounts/new_uid').set({
      role: 'teacher',
      superAdmin: true,
      status: 'active'
    }));
  });

  it('should DENY admin from updating profile to superAdmin=true', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('schools/school1/accounts/admin_uid').set({ status: 'active', role: 'admin' });
    });
    const db = testEnv.authenticatedContext('admin_uid', { role: 'admin' }).firestore();

    await assertFails(db.doc('schools/school1/accounts/admin_uid').update({
      superAdmin: true
    }));
  });

  it('should allow superAdmin to create admin account', async () => {
    const db = testEnv.authenticatedContext('super1', { role: 'admin', superAdmin: true }).firestore();
    await assertSucceeds(db.doc('schools/school1/accounts/new_admin2').set({ role: 'admin', status: 'active' }));
  });



  it('should allow parent to read linked child via parentStudents index', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('schools/school1/accounts/parent1').set({ status: 'active', role: 'parent' });
      await db.doc('schools/school1/accounts/student1').set({ status: 'active', role: 'student', schoolClass: 'classA' });
      await db.doc('schools/school1/parentStudents/parent1_student1').set({ parentId: 'parent1', studentId: 'student1' });
    });

    const db = testEnv.authenticatedContext('parent1', { role: 'parent' }).firestore();
    await assertSucceeds(db.doc('schools/school1/accounts/student1').get());
  });

  it('should DENY parent from reading unlinked child', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('schools/school1/accounts/student2').set({ status: 'active', role: 'student', schoolClass: 'classB' });
    });

    const db = testEnv.authenticatedContext('parent1', { role: 'parent' }).firestore();
    await assertFails(db.doc('schools/school1/accounts/student2').get());
  });

  it('should DENY parent from creating parentStudents link', async () => {
    const db = testEnv.authenticatedContext('parent1', { role: 'parent' }).firestore();
    await assertFails(db.doc('schools/school1/parentStudents/parent1_student2').set({ parentId: 'parent1', studentId: 'student2' }));
  });

  it('should allow admin to create parentStudents link', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('schools/school1/accounts/admin1').set({ status: 'active', role: 'admin' });
    });
    const db = testEnv.authenticatedContext('admin1', { role: 'admin' }).firestore();
    await assertSucceeds(db.doc('schools/school1/parentStudents/parent1_student2').set({ parentId: 'parent1', studentId: 'student2' }));
  });



  it('should DENY student from updating account role, status, or superAdmin', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('schools/school1/accounts/student1').set({ status: 'active', role: 'student' });
    });
    const db = testEnv.authenticatedContext('student1', { role: 'student' }).firestore();

    await assertFails(db.doc('schools/school1/accounts/student1').update({ role: 'admin' }));
    await assertFails(db.doc('schools/school1/accounts/student1').update({ status: 'deleted' }));
    await assertFails(db.doc('schools/school1/accounts/student1').update({ superAdmin: true }));
    await assertSucceeds(db.doc('schools/school1/accounts/student1').update({ phone: '+996555123456' }));
  });



  it('should DENY student from updating grade or changing late=false in homeworkSubmissions', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('schools/school1/accounts/student1').set({ status: 'active', role: 'student' });
    });
    const db = testEnv.authenticatedContext('student1', { role: 'student' }).firestore();
    const subRef = db.doc('schools/school1/homeworkSubmissions/sub1');

    await assertSucceeds(subRef.set({ studentId: 'student1', fileUrl: 'url' }));
    await assertFails(subRef.update({ grade: 5 }));
    await assertFails(subRef.update({
      late: false
    }));
  });

  it('should DENY teacher from creating grade for student in different class', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const disabledDb = context.firestore();
      await disabledDb.doc('schools/school1/accounts/teacher1').set({ status: 'active', role: 'teacher' });
      await disabledDb.doc('schools/school1/teacherClasses/teacher1_classA').set({ active: true });
      await disabledDb.doc('schools/school1/accounts/student2').set({ status: 'active', role: 'student', schoolClass: 'classB' });
    });

    const db = testEnv.authenticatedContext('teacher1', { role: 'teacher' }).firestore();
    const gradeRef = db.doc('schools/school1/grades/grade1');
    await assertFails(gradeRef.set({
      teacherId: 'teacher1',
      classId: 'classA',
      studentId: 'student2',
      grade: 5
    }));
  });

  it('should allow teacher to create own audit log', async () => {
    const context = testEnv.authenticatedContext('teacher1', { role: 'teacher' });
    const db = context.firestore();

    await assertSucceeds(db.doc('schools/school1/auditLogs/log1').set({
      actorId: 'teacher1',
      actorRole: 'teacher',
      createdAt: context.database.FieldValue.serverTimestamp()
    }));
  });

  it('should DENY student from creating audit log for another actorId', async () => {
    const context = testEnv.authenticatedContext('student1', { role: 'student' });
    const db = context.firestore();

    await assertFails(db.doc('schools/school1/auditLogs/log2').set({
      actorId: 'teacher1',
      actorRole: 'teacher',
      createdAt: context.database.FieldValue.serverTimestamp()
    }));
  });

  it('should DENY admin from editing existing audit log unless superAdmin', async () => {
    const adminDb = testEnv.authenticatedContext('admin1', { role: 'admin' }).firestore();

    await assertFails(adminDb.doc('schools/school1/auditLogs/log1').update({
      action: 'fake_action'
    }));

    const superAdminDb = testEnv.authenticatedContext('super1', { superAdmin: true }).firestore();
    await assertSucceeds(superAdminDb.doc('schools/school1/auditLogs/log1').update({
      action: 'deleted_by_superadmin'
    }));
  });



  it('should allow parent to read class files via parentClasses index', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('schools/school1/accounts/parent1').set({ status: 'active', role: 'parent' });
      await db.doc('schools/school1/parentClasses/parent1_classA').set({ parentId: 'parent1', classId: 'classA' });
      await db.doc('schools/school1/files/file1').set({ classId: 'classA' });
    });

    const db = testEnv.authenticatedContext('parent1', { role: 'parent' }).firestore();
    await assertSucceeds(db.doc('schools/school1/files/file1').get());
  });

  it('should DENY parent from reading unrelated class files', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc('schools/school1/accounts/parent1').set({ status: 'active', role: 'parent' });
      await db.doc('schools/school1/files/file2').set({ classId: 'classB' });
    });

    const db = testEnv.authenticatedContext('parent1', { role: 'parent' }).firestore();
    await assertFails(db.doc('schools/school1/files/file2').get());
  });
});