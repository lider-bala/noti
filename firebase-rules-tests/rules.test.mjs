import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, setLogLevel } from 'firebase/firestore';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

// Для корректной работы с путями в ESM
const __dirname = dirname(fileURLToPath(import.meta.url));

async function runTests() {
  console.log('Запуск тестов Firebase Rules...');
  
  // Отключаем внутренние gRPC-логи, чтобы вывод был чистым
  setLogLevel('error');

  const firestoreRules = readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8');
  const storageRules = readFileSync(resolve(__dirname, '../storage.rules'), 'utf8');

  const testEnv = await initializeTestEnvironment({
    projectId: 'noti-c3136-test',
    firestore: { rules: firestoreRules },
    storage: { rules: storageRules },
  });

  try {
    async function resetData() {
      await testEnv.clearFirestore();
    }

    // Хелперы для создания контекстов
    const getSuperAdminDb = () => testEnv.authenticatedContext('admin1', { superAdmin: true }).firestore();
    const getUnauthDb = () => testEnv.unauthenticatedContext().firestore();
    const getAdminDb = () => testEnv.authenticatedContext('admin1', { role: 'admin' }).firestore();
    const getParentDb = (uid = 'parent1') => testEnv.authenticatedContext(uid, { role: 'parent' }).firestore();
    const getTeacherDb = (uid = 'teacher1') => testEnv.authenticatedContext(uid, { role: 'teacher' }).firestore();
    const getStudentDb = (uid = 'student1') => testEnv.authenticatedContext(uid, { role: 'student' }).firestore();

    {
      await resetData();
      console.log('Тест 1: superAdmin может записывать школы');
      await assertSucceeds(setDoc(doc(getSuperAdminDb(), 'schools/school1'), { name: 'Test School' }));
    }

    {
      await resetData();
      console.log('Тест 2: аноним не может читать аккаунты');
      await assertFails(getDoc(doc(getUnauthDb(), 'schools/school1/accounts/user1')));
    }

    // --- ТЕСТЫ АДМИНИСТРАТОРА ---
    {
      await resetData();
      console.log('Тест 3: admin cannot create superAdmin');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'schools/school1/accounts/admin1'), { status: 'active', role: 'admin' });
      });
      await assertFails(setDoc(doc(getAdminDb(), 'schools/school1/accounts/new_super'), { role: 'teacher', superAdmin: true, status: 'active' }));
    }

    {
      await resetData();
      console.log('Тест 4: admin cannot escalate own profile');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'schools/school1/accounts/admin1'), { status: 'active', role: 'admin' });
      });
      await assertFails(updateDoc(doc(getAdminDb(), 'schools/school1/accounts/admin1'), { superAdmin: true }));
    }

    {
      await resetData();
      console.log('Тест 5: admin can create parentStudents');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/admin1'), { status: 'active', role: 'admin' });
        await setDoc(doc(db, 'schools/school1/accounts/parent_admin_create'), { status: 'active', role: 'parent' });
        await setDoc(doc(db, 'schools/school1/accounts/student_admin_create'), { status: 'active', role: 'student' });
      });
      await assertSucceeds(setDoc(doc(getAdminDb(), 'schools/school1/parentStudents/parent_admin_create_student_admin_create'), { parentId: 'parent_admin_create', studentId: 'student_admin_create' }));
    }

    // --- ТЕСТЫ РОДИТЕЛЯ ---
    {
      await resetData();
      console.log('Тест 6: parent can read linked child via parentStudents');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/parent1'), { status: 'active', role: 'parent' });
        await setDoc(doc(db, 'schools/school1/accounts/student1'), { status: 'active', role: 'student' });
        await setDoc(doc(db, 'schools/school1/parentStudents/parent1_student1'), { parentId: 'parent1', studentId: 'student1' });
      });
      await assertSucceeds(getDoc(doc(getParentDb(), 'schools/school1/accounts/student1')));
    }

    {
      await resetData();
      console.log('Тест 7: parent cannot read unlinked child');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/parent_t7'), { status: 'active', role: 'parent' });
        await setDoc(doc(db, 'schools/school1/accounts/student_t7_unlinked'), { status: 'active', role: 'student' });
      });
      await assertFails(getDoc(doc(getParentDb('parent_t7'), 'schools/school1/accounts/student_t7_unlinked')));
    }

    {
      await resetData();
      console.log('Тест 8: parent cannot create parentStudents');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/parent1'), { status: 'active', role: 'parent' });
        await setDoc(doc(db, 'schools/school1/accounts/student3'), { status: 'active', role: 'student' });
      });
      await assertFails(setDoc(doc(getParentDb(), 'schools/school1/parentStudents/parent1_student3'), { parentId: 'parent1', studentId: 'student3' }));
    }

    {
      await resetData();
      console.log('Тест 9: parent can read files via parentClasses');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/parent1'), { status: 'active', role: 'parent' });
        await setDoc(doc(db, 'schools/school1/parentClasses/parent1_classA'), { parentId: 'parent1', classId: 'classA' });
        await setDoc(doc(db, 'schools/school1/files/file_classA'), { classId: 'classA' });
      });
      await assertSucceeds(getDoc(doc(getParentDb(), 'schools/school1/files/file_classA')));
    }

    {
      await resetData();
      console.log('Тест 10: parent cannot read unrelated class files');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/parent1'), { status: 'active', role: 'parent' });
        await setDoc(doc(db, 'schools/school1/parentClasses/parent1_classA'), { parentId: 'parent1', classId: 'classA' });
        await setDoc(doc(db, 'schools/school1/files/file_classB'), { classId: 'classB' });
      });
      await assertFails(getDoc(doc(getParentDb(), 'schools/school1/files/file_classB')));
    }

    // --- ТЕСТЫ УЧИТЕЛЯ ---
    {
      await resetData();
      console.log('Тест 11: teacher can read homework submissions from own class');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/teacher1'), { status: 'active', role: 'teacher' });
        await setDoc(doc(db, 'schools/school1/teacherClasses/teacher1_classA'), { active: true });
        await setDoc(doc(db, 'schools/school1/accounts/student1'), { status: 'active', role: 'student', schoolClass: 'classA' });
        await setDoc(doc(db, 'schools/school1/homeworkSubmissions/sub1'), { studentId: 'student1' });
      });
      await assertSucceeds(getDoc(doc(getTeacherDb(), 'schools/school1/homeworkSubmissions/sub1')));
    }

    {
      await resetData();
      console.log('Тест 12: teacher cannot read homework submissions from чужого класса');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/teacher1'), { status: 'active', role: 'teacher' });
        await setDoc(doc(db, 'schools/school1/teacherClasses/teacher1_classA'), { active: true });
        await setDoc(doc(db, 'schools/school1/accounts/student2'), { status: 'active', role: 'student', schoolClass: 'classB' });
        await setDoc(doc(db, 'schools/school1/homeworkSubmissions/sub2'), { studentId: 'student2' });
      });
      await assertFails(getDoc(doc(getTeacherDb(), 'schools/school1/homeworkSubmissions/sub2')));
    }

    {
      await resetData();
      console.log('Тест 13: teacher cannot grade student outside class');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/teacher1'), { status: 'active', role: 'teacher' });
        await setDoc(doc(db, 'schools/school1/teacherClasses/teacher1_classA'), { active: true });
        await setDoc(doc(db, 'schools/school1/accounts/student2'), { status: 'active', role: 'student', schoolClass: 'classB' });
      });
      await assertFails(setDoc(doc(getTeacherDb(), 'schools/school1/grades/new_grade'), { teacherId: 'teacher1', classId: 'classA', studentId: 'student2', grade: 5 }));
    }

    // --- ТЕСТЫ УЧЕНИКА ---
    {
      await resetData();
      console.log('Тест 14: student cannot update grade/late/checkedAt in submission');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/student1'), { status: 'active', role: 'student' });
        await setDoc(doc(db, 'schools/school1/homeworkSubmissions/sub1'), { studentId: 'student1', grade: null, late: false });
      });
      await assertFails(updateDoc(doc(getStudentDb(), 'schools/school1/homeworkSubmissions/sub1'), { grade: 5 }));
      await assertFails(updateDoc(doc(getStudentDb(), 'schools/school1/homeworkSubmissions/sub1'), { late: true }));
      await assertFails(updateDoc(doc(getStudentDb(), 'schools/school1/homeworkSubmissions/sub1'), { checkedAt: new Date() }));
    }

    {
      await resetData();
      console.log('Тест 15: Проверка разрешенного обновления (например, обновление fileUrl)');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'schools/school1/accounts/student1'), { status: 'active', role: 'student' });
        await setDoc(doc(db, 'schools/school1/homeworkSubmissions/sub1'), { studentId: 'student1', fileUrl: 'old_url' });
      });
      await assertSucceeds(updateDoc(doc(getStudentDb(), 'schools/school1/homeworkSubmissions/sub1'), { fileUrl: 'new_url' }));
    }

    console.log('✅ Все расширенные тесты безопасности успешно пройдены!');
  } catch (error) {
    console.error('❌ Ошибка во время тестирования:', error);
    process.exit(1);
  } finally {
    console.log('Очистка тестового окружения...');
    await testEnv.cleanup();
  }
}

runTests();