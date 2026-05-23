// Generate SemesterMate-Brief.pdf — a clean 2-page brief for a teacher.
// Run:  node build_brief.js

const PDFDocument = require('pdfkit');
const fs = require('fs');

const OUT = 'SemesterMate-Brief.pdf';

// --- Brand palette (matches the app) ---
const INDIGO = '#4F46E5';
const INK    = '#0F172A';
const MUTED  = '#64748B';
const LIGHT  = '#F1F5F9';
const ROW_A  = '#F8FAFC';
const BORDER = '#E2E8F0';

const doc = new PDFDocument({
  size: 'A4',
  margins: { top: 50, bottom: 45, left: 55, right: 55 },
  info: {
    Title: 'SemesterMate — Project Brief',
    Author: 'SemesterMate',
    Subject: 'Academic project brief',
  },
});
doc.pipe(fs.createWriteStream(OUT));

const M = doc.page.margins;
const PAGE_W = doc.page.width - M.left - M.right;
const LEFT = M.left;

// ----------------------------------------------------------------
// Helpers — every section resets doc.x to LEFT to avoid drift.
// ----------------------------------------------------------------

function h1(text) {
  doc.x = LEFT;
  doc.font('Helvetica-Bold').fontSize(26).fillColor(INDIGO)
     .text(text, { width: PAGE_W });
  doc.moveDown(0.05);
}

function subtitle(text) {
  doc.x = LEFT;
  doc.font('Helvetica-Oblique').fontSize(10.5).fillColor(MUTED)
     .text(text, { width: PAGE_W });
  doc.moveDown(0.7);
}

function h2(text) {
  doc.x = LEFT;
  doc.moveDown(0.4);
  doc.font('Helvetica-Bold').fontSize(13).fillColor(INDIGO)
     .text(text, { width: PAGE_W });
  doc.moveDown(0.2);
}

function body(text) {
  doc.x = LEFT;
  doc.font('Helvetica').fontSize(10).fillColor(INK)
     .text(text, { width: PAGE_W, align: 'left', lineGap: 2 });
  doc.moveDown(0.15);
}

function code(text) {
  doc.x = LEFT;
  doc.font('Courier').fontSize(8.8).fillColor(INDIGO)
     .text(text, { width: PAGE_W });
  doc.moveDown(0.1);
}

function bullets(items) {
  const indent = 14;
  items.forEach(item => {
    const y = doc.y;
    // bullet dot at fixed x
    doc.circle(LEFT + 4, y + 5.5, 1.7).fillColor(INDIGO).fill();
    // hanging-indented text — do NOT touch doc.x outside the call
    doc.font('Helvetica').fontSize(10).fillColor(INK)
       .text(item, LEFT + indent, y, {
         width: PAGE_W - indent,
         lineGap: 2,
       });
    // ensure cursor returns to left margin for the next section
    doc.x = LEFT;
    doc.moveDown(0.1);
  });
  doc.moveDown(0.2);
}

function kvTable(rows, col1Width = 120) {
  const padX = 10;
  const padY = 6;
  const col2Width = PAGE_W - col1Width;

  rows.forEach((row, i) => {
    const [k, v] = row;

    doc.font('Helvetica').fontSize(9.5);
    const kH = doc.heightOfString(k, { width: col1Width - padX * 2 });
    const vH = doc.heightOfString(v, { width: col2Width - padX * 2 });
    const rowH = Math.max(kH, vH) + padY * 2;

    const y0 = doc.y;

    // zebra background
    doc.save();
    doc.rect(LEFT, y0, PAGE_W, rowH)
       .fillColor(i % 2 === 0 ? LIGHT : ROW_A).fill();
    doc.restore();

    // bottom hairline
    doc.save();
    doc.moveTo(LEFT, y0 + rowH).lineTo(LEFT + PAGE_W, y0 + rowH)
       .strokeColor(BORDER).lineWidth(0.5).stroke();
    doc.restore();

    // key column
    doc.fillColor(INDIGO).font('Helvetica-Bold').fontSize(9.5)
       .text(k, LEFT + padX, y0 + padY, {
         width: col1Width - padX * 2, lineGap: 1,
       });

    // value column
    doc.fillColor(INK).font('Helvetica').fontSize(9.5)
       .text(v, LEFT + col1Width + padX, y0 + padY, {
         width: col2Width - padX * 2, lineGap: 1,
       });

    // explicitly position cursor at bottom of this row
    doc.x = LEFT;
    doc.y = y0 + rowH;
  });
  doc.moveDown(0.5);
}

function attribution(text) {
  doc.moveDown(0.6);
  doc.x = LEFT;
  doc.font('Helvetica-Oblique').fontSize(8.5).fillColor(MUTED)
     .text(text, { width: PAGE_W, align: 'center', lineGap: 1 });
}

// ================================================================
// PAGE 1
// ================================================================

h1('SemesterMate');
subtitle(
  'A student productivity and academic management mobile app  -  ' +
  'Mobile Application Development, 6th Semester'
);

h2('The problem');
body(
  'University students juggle CT exams, lab exams, vivas, assignments, ' +
  'finals, attendance, semester fees and GPA across notebooks, sticky ' +
  'notes and memory. Deadlines slip; attendance drops below 75% silently; ' +
  'GPA is recalculated by hand each semester. There is no single place ' +
  'for all of it.'
);

h2('The solution');
body(
  'SemesterMate is a single Android app that centralises every academic ' +
  'obligation. Data is synced to the cloud (survives phone changes), ' +
  'protected by per-user Row Level Security at the database layer, and ' +
  'augmented with on-device reminders so deadlines are never missed.'
);

h2('Key features');
bullets([
  'Authentication — email/password via Supabase Auth, persistent sessions, password reset.',
  'Dashboard — greeting, upcoming exams, fee due, attendance % and CGPA at a glance, weekly productivity chart.',
  'Task system — full CRUD over CT / Lab / Viva / Assignment / Final, with priorities, status, search, type filters, list and calendar views.',
  'Attendance tracker — per-subject classes, auto-percentage, <75% warning, analytics bar chart with a 75% guideline.',
  'Semester fee tracker — total / paid / due, deadline reminders, progress bars, overdue flags.',
  'GPA and CGPA — add courses with credits and grades, auto semester GPA, cumulative CGPA, multi-semester trend line.',
  'Local notifications — one-hour-before reminders for tasks, one-day-before reminders for fee deadlines.',
  'Profile and settings — editable profile, light/dark theme, notification toggle.',
]);

h2('Tech stack');
kvTable([
  ['Frontend',      'Flutter 3.32 (Dart 3), Material 3, Google Fonts (Inter)'],
  ['State',         'Riverpod (AsyncNotifier + Provider)'],
  ['Routing',       'go_router with auth guard and ShellRoute'],
  ['Backend',       'Supabase: PostgreSQL + GoTrue Auth'],
  ['Security',      'Row Level Security policies on every table'],
  ['Charts',        'fl_chart (bar and line)'],
  ['Calendar',      'table_calendar'],
  ['Notifications', 'flutter_local_notifications + timezone'],
  ['DevOps',        'GitHub Actions: release APK built and uploaded per push'],
]);

// ================================================================
// PAGE 2
// ================================================================
doc.addPage();

h2('Architecture');
body('Clean three-layer architecture with strict separation of concerns:');
bullets([
  'Models — pure Dart data classes with fromMap / toInsertMap for Supabase JSON.',
  'Repositories — single source of truth for each entity; wrap the Supabase client.',
  'Providers (Riverpod) — reactive state; AsyncNotifier exposes loading / data / error.',
  'Screens and widgets — UI consumes providers; never talks to the DB directly.',
  'Core — theme, env (via --dart-define), constants, validators.',
]);

h2('Database and security');
body(
  'PostgreSQL schema with five tables (profiles, tasks, attendance, ' +
  'semester_fees, gpa_records) plus a trigger that auto-creates a profile ' +
  'row on signup. Every table has Row Level Security enabled with policies ' +
  'of the form:'
);
code('create policy "tasks_select_own" on tasks for select using (auth.uid() = user_id);');
body(
  'Even with the anon key embedded in the APK, a malicious user cannot read ' +
  'another user\'s data — Postgres enforces ownership at the row level. The ' +
  'privileged service_role key never ships with the app.'
);

h2('Build and deployment');
bullets([
  'GitHub Actions regenerates the android/ folder on every build, patches the manifest for notification permissions, enables core library desugaring, and runs flutter build apk --release.',
  'Secrets (SUPABASE_URL, SUPABASE_ANON_KEY) are injected via --dart-define from GitHub repository secrets — never committed to source.',
  'The release APK is uploaded as a GitHub artifact, downloadable from the Actions UI.',
]);

h2("For a JavaScript developer's mind");
kvTable([
  ['JSX component tree',      'Flutter widget tree (everything is a Widget)'],
  ['React Context + reducers','Riverpod providers + AsyncNotifier'],
  ['React Router',            'go_router (declarative, with redirect guards)'],
  ['Tailwind / shadcn',       'Material 3 ThemeData + custom theme.dart'],
  ['npm + package.json',      'pub.dev + pubspec.yaml'],
  ['recharts / chart.js',     'fl_chart'],
  ['Vite hot reload',         'Flutter hot reload (sub-second)'],
  ['Supabase JS SDK',         'supabase_flutter (same primitives, Dart bindings)'],
], 160);

h2('Outcome');
body(
  'A production-style, demo-ready Android app: signed release APK built ' +
  'from a 64-file Flutter codebase (~6,700 lines of Dart), end-to-end ' +
  'Supabase integration with Row Level Security, six full feature modules, ' +
  'light/dark theme, local notifications, calendar and chart visualisations ' +
  '— all buildable in under four minutes on GitHub-hosted CI.'
);

attribution(
  'Source: github.com/Akram-hossain/Smart-Queue-Mobile-App     ' +
  'APK: Actions tab  >  latest run  >  Artifacts  >  semestermate-release-apk'
);

doc.end();
console.log('Generated', OUT);
