# Security rules test matrix

Run rules tests with the Firebase Emulator Suite:

```bash
firebase emulators:exec --only firestore,storage "npm test"
```

Required scenarios:

- blocked/deleted users cannot read or write any protected document.
- admin can manage accounts, classes, lessons, and registration requests.
- admin cannot set `superAdmin: true` or delete school metadata unless custom
  claim `superAdmin == true` is present.
- teacher can create grades, attendance, homework, meetings, and class files
  only for classes linked through `teacherClasses/{teacherId_classId}`.
- student can read own grades/submissions and class lessons/homework/files only.
- student cannot read another student's grades, submissions, or private files.
- parent can read only the exact `linkedStudentId` child's grades, attendance,
  homework, and class files.
- parent without `linkedStudentId` cannot fall back to class-level student data.
- Storage rejects files over 25 MB and MIME types outside the allowlist.
