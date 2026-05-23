"""Generate SemesterMate-Brief.pdf — a 2-page project brief for academic presentation."""
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak,
)

# --- Brand palette (matches the app) ---
INDIGO = colors.HexColor("#4F46E5")
VIOLET = colors.HexColor("#8B5CF6")
INK = colors.HexColor("#0F172A")
MUTED = colors.HexColor("#64748B")
LIGHT = colors.HexColor("#F1F5F9")
SUCCESS = colors.HexColor("#10B981")

# --- Styles ---
styles = getSampleStyleSheet()

H1 = ParagraphStyle(
    "H1", parent=styles["Title"],
    fontName="Helvetica-Bold", fontSize=24, leading=28,
    textColor=INDIGO, spaceAfter=2, alignment=0,
)
SUBTITLE = ParagraphStyle(
    "Sub", parent=styles["Normal"],
    fontName="Helvetica-Oblique", fontSize=11, leading=14,
    textColor=MUTED, spaceAfter=12,
)
H2 = ParagraphStyle(
    "H2", parent=styles["Heading2"],
    fontName="Helvetica-Bold", fontSize=13, leading=16,
    textColor=INDIGO, spaceBefore=10, spaceAfter=6,
)
BODY = ParagraphStyle(
    "Body", parent=styles["BodyText"],
    fontName="Helvetica", fontSize=10, leading=14,
    textColor=INK, spaceAfter=4,
)
BULLET = ParagraphStyle(
    "Bullet", parent=BODY, leftIndent=14, bulletIndent=2,
    spaceAfter=2,
)
SMALL = ParagraphStyle(
    "Small", parent=BODY, fontSize=9, leading=12, textColor=MUTED,
)
FOOTER = ParagraphStyle(
    "Foot", parent=BODY, fontSize=8, leading=10, textColor=MUTED,
    alignment=1,
)


def bullets(items):
    return [Paragraph(f"•&nbsp;&nbsp;{t}", BULLET) for t in items]


def kv_table(rows, col1_w=4.0, col2_w=12.0):
    t = Table(rows, colWidths=[col1_w * cm, col2_w * cm])
    t.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 9.5),
        ("TEXTCOLOR", (0, 0), (0, -1), INDIGO),
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
        ("TEXTCOLOR", (1, 0), (1, -1), INK),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("BACKGROUND", (0, 0), (-1, -1), LIGHT),
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [LIGHT, colors.white]),
        ("LINEBELOW", (0, 0), (-1, -1), 0.25, colors.HexColor("#E2E8F0")),
        ("ROUNDEDCORNERS", [6, 6, 6, 6]),
    ]))
    return t


# --- Document ---
doc = SimpleDocTemplate(
    "SemesterMate-Brief.pdf",
    pagesize=A4,
    leftMargin=1.8 * cm, rightMargin=1.8 * cm,
    topMargin=1.6 * cm, bottomMargin=1.5 * cm,
    title="SemesterMate — Project Brief",
    author="SemesterMate",
)

story = []

# ===================== PAGE 1 =====================
story.append(Paragraph("SemesterMate", H1))
story.append(Paragraph(
    "A student productivity &amp; academic management mobile app · "
    "Mobile Application Development — 6th Semester",
    SUBTITLE,
))

# Problem & Solution
story.append(Paragraph("The problem", H2))
story.append(Paragraph(
    "University students juggle CT exams, lab exams, vivas, assignments, "
    "finals, attendance, semester fees and GPA — across notebooks, sticky "
    "notes and memory. Deadlines slip; attendance drops below 75% silently; "
    "GPA is calculated by hand. There is no single place for all of it.",
    BODY,
))

story.append(Paragraph("The solution", H2))
story.append(Paragraph(
    "<b>SemesterMate</b> is a single mobile app that centralises every "
    "academic obligation. Data is synced to the cloud (so it survives "
    "phone changes), protected by per-user Row Level Security, and "
    "augmented with on-device reminders so deadlines are never missed.",
    BODY,
))

# Key features
story.append(Paragraph("Key features", H2))
story.extend(bullets([
    "<b>Authentication</b> — email/password with Supabase Auth, persistent sessions, password reset",
    "<b>Dashboard</b> — greeting, upcoming exams, fee due, attendance % &amp; CGPA at a glance, weekly productivity chart",
    "<b>Task system</b> — full CRUD over CT / Lab / Viva / Assignment / Final, with priorities, status, search, type filters, list and calendar views",
    "<b>Attendance tracker</b> — per-subject classes, auto-percentage, &lt;75% warning, analytics bar chart with a 75% guideline",
    "<b>Semester fee tracker</b> — total / paid / due, deadline reminders, progress bars, overdue flags",
    "<b>GPA &amp; CGPA</b> — add courses with credits &amp; grades, auto semester GPA, cumulative CGPA, multi-semester trend line",
    "<b>Local notifications</b> — scheduled reminders one hour before each task / one day before fee deadlines",
    "<b>Profile &amp; settings</b> — editable profile, light/dark theme, notification toggle",
]))

# Tech stack table
story.append(Paragraph("Tech stack", H2))
story.append(kv_table([
    ["Frontend", "Flutter 3.32 (Dart 3), Material 3, Google Fonts (Inter)"],
    ["State", "Riverpod (AsyncNotifier + Provider)"],
    ["Routing", "go_router with auth guard &amp; ShellRoute"],
    ["Backend", "Supabase — PostgreSQL + GoTrue Auth"],
    ["Security", "Row Level Security policies on every table"],
    ["Charts", "fl_chart (bar &amp; line)"],
    ["Calendar", "table_calendar"],
    ["Notifications", "flutter_local_notifications + timezone"],
    ["DevOps", "GitHub Actions — release APK built &amp; uploaded per push"],
]))

story.append(PageBreak())

# ===================== PAGE 2 =====================
story.append(Paragraph("Architecture", H2))
story.append(Paragraph(
    "Clean three-layer architecture with strict separation of concerns:",
    BODY,
))
story.extend(bullets([
    "<b>Models</b> — pure Dart data classes with <code>fromMap</code> / <code>toInsertMap</code> for Supabase JSON",
    "<b>Repositories</b> — single source of truth for each entity; wrap the Supabase client",
    "<b>Providers</b> (Riverpod) — reactive state; <code>AsyncNotifier</code> exposes loading / data / error",
    "<b>Screens &amp; widgets</b> — UI consumes providers; never talks to the DB directly",
    "<b>Core</b> — theme, env (<code>--dart-define</code>), constants, validators",
]))

# Database & security
story.append(Paragraph("Database &amp; security", H2))
story.append(Paragraph(
    "PostgreSQL schema with five tables (<code>profiles, tasks, attendance, "
    "semester_fees, gpa_records</code>) plus a trigger that auto-creates a "
    "profile row on signup. Every table has Row Level Security enabled with "
    "policies of the form:",
    BODY,
))
story.append(Spacer(1, 4))
story.append(Paragraph(
    "<font face='Courier' size='9' color='#4F46E5'>"
    "create policy &quot;tasks_select_own&quot; on tasks "
    "for select using (auth.uid() = user_id);"
    "</font>",
    BODY,
))
story.append(Paragraph(
    "Even with the anon key in the APK, a malicious user cannot read another "
    "user's data — Postgres enforces ownership at the row level. The "
    "<code>service_role</code> key never ships with the app.",
    BODY,
))

# Build pipeline
story.append(Paragraph("Build &amp; deployment", H2))
story.extend(bullets([
    "<b>GitHub Actions</b> regenerates the <code>android/</code> folder on every build (keeps repo lean), patches the manifest for notification permissions, enables Android core library desugaring, and runs <code>flutter build apk --release</code>",
    "<b>Secrets</b> (<code>SUPABASE_URL</code>, <code>SUPABASE_ANON_KEY</code>) are injected via <code>--dart-define</code> from repo secrets — never committed to source",
    "<b>Release APK</b> is uploaded as a GitHub artifact, downloadable from the Actions UI",
]))

# JS-developer Rosetta stone
story.append(Paragraph("For a JavaScript developer's mind", H2))
story.append(kv_table([
    ["JSX component tree", "Flutter widget tree (everything is a Widget)"],
    ["React Context + reducers", "Riverpod providers + AsyncNotifier"],
    ["React Router", "go_router (declarative, with redirect guards)"],
    ["Tailwind / shadcn", "Material 3 ThemeData + custom theme.dart"],
    ["npm + package.json", "pub.dev + pubspec.yaml"],
    ["recharts / chart.js", "fl_chart"],
    ["Vite hot reload", "Flutter hot reload (sub-second)"],
    ["Supabase JS SDK", "supabase_flutter (same primitives, Dart bindings)"],
]))

# Outcome
story.append(Paragraph("Outcome", H2))
story.append(Paragraph(
    "A production-style, demo-ready Android app: signed release APK built "
    "from a 64-file Flutter codebase (~6,700 lines of Dart), end-to-end "
    "Supabase integration with RLS, six full feature modules, light/dark "
    "theme, local notifications, calendar + chart visualisations — all "
    "buildable in under four minutes on GitHub-hosted CI.",
    BODY,
))

# Footer
story.append(Spacer(1, 14))
story.append(Paragraph(
    "Source: github.com/Akram-hossain/Smart-Queue-Mobile-App · "
    "APK: GitHub Actions → latest run → Artifacts → semestermate-release-apk",
    FOOTER,
))

doc.build(story)
print("OK")
