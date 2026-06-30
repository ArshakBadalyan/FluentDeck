# Strapi Math

### Staging deployment (Hetzner, Docker, IP-only)

| Environment | Guide |
|-------------|--------|
| **Staging** | **[STAGING-DEPLOYMENT.md](./STAGING-DEPLOYMENT.md)** — Docker, DB, GitHub Actions (IP-only) |
| **Production** | **[PRODUCTION-DEPLOYMENT.md](./PRODUCTION-DEPLOYMENT.md)** — Docker, DB, manual deploy |

### How to install
``` bash
# clone project
$ git clone https://github.com/sahakyan-dev/strapi-math.git
# go to project folder
$ cd strapi-math/
# Copy the .env.example file to .env file
$ cp .env.example .env
# install dependencies
$ npm install # Or yarn install
# Build admin UI 
$ npm run build --clean
```

### Run project
``` bash
# serve with hot reload at localhost:1337
$ npm run start
# OR run development mode 
$ npm run develop
```
When the project is launched for the first time, a registration link opens in the browser - `http://localhost:1337/admin/auth/register-admin`
<br/>
Fill in your data for your administrator user and click **Let's start**.

### Give correct permissions
1. Click on **Settings** under **GENERAL** in the side menu
2. Click on **Roles** under **Users and Permissions Plugin**.
3. It will display a list of roles. Click on **Public**,
scroll down under **Permissions**, click on:
4. **Users-permissions**, then:<br/>
   **Auth** - Select all <br/>
   **Permissions** - Select all <br/>
   **User** - Select all <br/>
5. Click save, then go back.
6. Click on **Roles** under **Users and Permissions Plugin**.
7. Click on **Authenticated**. then select the following permissions:

- **Answer**: _find_ and _findOne_
- **Category**: _find_, _findOne_, _getLastCategory_, _getPastCategories_
- **Category-class**: _find_ and _findOne_
- **Institution**: _create_, _find_, _findOne_, _getCourses_
- **Installation**: _find_, _findOne_, _delete_
- **Notification**: _create_, _find_, _findOne_, _update_
- **Parents-email**: select all
- **Practice-result**: _create_, _find_, _findOne_
- **Question-report**: _create_ (in-app “report a problem”; user id comes from JWT — do not expose _create_ on **Public**)
- **Question**: _find_, _findOne_, _getAnsweredQuestions_, _getNonAnsweredQuestions_, _getQuizQuestions_, _getTopicQuestions_
- **User-answers**: _create_, _find_, _findOne_
- **Users-permissions**:

  - Select all in _Auth_ section
  - Select **getPermissions**
  - Select _deleteRole_ in _Role_ section
  - Select all in _User_ section

### For production server
``` bash
# build for production and launch server
$ npm run build
$ npm start
```

### Database

All manual changes to database should be done via migration files. For creating migration file you need to run 
``` bash
$ node database/migrate.js FILENAME
```
where FILENAME is a name of migration, like "add_new_ questions", "add_new_category", ... . FILENAME should be without spaces. New file will be created in `database/migrations/` folder. You need to make changes in that file. If you don't know how to do it, just check these instructions:

https://docs.strapi.io/developer-docs/latest/developer-resources/database-migrations.html

https://knexjs.org/guide/query-builder.html#insert

***IMPORTANT - Each migration file runs only ones on first run of the project (`npm run start` or `yarn start`) after creating it, so think twice before running the project with new migration file.***

### Deploy

`git push heroku HEAD:main`

`heroku logs`
or

`heroku logs --tail`
or

`heroku logs --tail -a math-arm-app | grep '\[cron\]'`
or

`heroku logs -n 1500`

### Heroku configs

`heroku config`

`heroku config:set KEY=VALUE`

### Version Dependencies

If your machine has problem running the application, please double-check the versions of `node` and `npm` to fix those or other possible solution that may or may not work would be to delete `package-lock.json` file and removing `node_modules` and then doing `npm install` or the third option would be to go with the docker setup which is mentioned in the readme.

**OTHERWISE**, the versions that you should use are the ones mentioned below.

> node v18 (18.15.0)

> yarn v1 (1.19.1)

or if you don't prefer doing the above you could also make use of NVM (Node Version Manager - POSIX-compliant bash script to manage multiple active node.js versions) as per your convenience.

[NVM for windows](https://content.breatheco.de/en/how-to/nvm-install-windows#:~:text=Steps%20to%20install%20with%20nvm%3A&text=Install%20nvm%20Go%20to%20your,that%20you%20will%20hit%20too.)

[NVM for mac](https://tecadmin.net/install-nvm-macos-with-homebrew/)

## Teacher accounts — Phase 1

### Database migrations

```bash
node database/migrate.js 2026-06-02T10-00-00-add-institution-allowed-email-domains.js
node database/migrate.js 2026-06-02T10-01-00-add-user-account-type.js
node database/migrate.js 2026-06-02T10-02-00-create-teacher-role.js
```

Restart Strapi so bootstrap creates/links the **Teacher** role permissions.

### School email domains

In Strapi Admin → **Institution** → edit a school → set **allowed_email_domains** (JSON array), e.g.:

```json
["gymnasium-example.de"]
```

### API

- `GET /api/institutions/validate-email-domain?email=user@school.de` (public)
- Register with `account_type`: `student` | `teacher`. **Teachers** must use a school email whose domain is listed on an Institution; **students** may use any email (Gmail, etc.) as before.

### Teacher approval & invite codes

| Field / rule | Purpose |
|---|---|
| `teacher_approved` (user, default `false`) | Teachers can log in but cannot use class APIs until `true` |
| `is_institution_admin` (user) | Can approve pending teachers **for their institution** via API |
| `is_admin` (user) | Platform admin — approve any teacher (API or Strapi Admin) |
| `teacher_invite_code` + `teacher_invite_code_year` (institution) | One code per school per calendar year; required on teacher signup |

**Migration:**

```bash
node database/migrate.js 2026-06-03T12-00-00-add-teacher-approval.js
```

Existing `account_type: teacher` users are **grandfathered** to `teacher_approved: true`.

**Strapi Admin (super-admin):** Users → edit teacher → set **teacher_approved** ✓. Institution → set or regenerate invite code (or use API below).

**Institution admin API** (JWT user with `is_institution_admin: true`):

| Method | Path | Description |
|---|---|---|
| GET | `/api/teacher-approvals/pending` | Pending teachers (scoped to institution) |
| POST | `/api/teacher-approvals/:userId/approve` | Approve teacher |
| POST | `/api/teacher-approvals/:userId/reject` | Reject (blocks account) |
| POST | `/api/institutions/:id/regenerate-teacher-invite` | New annual invite code |

**Teacher signup body:** `{ ..., "account_type": "teacher", "teacher_invite_code": "ABC12345" }`

---

## Teacher accounts — Phase 2

**Goal:** Teachers get a dedicated in-app experience after login. Server permissions are explicit and staging is ready for school emails.

### Scope

| In scope | Out of scope |
|---|---|
| Teacher-specific navigation shell | Classrooms / roster (Phase 3–4) |
| Teacher profile (school, badge) | Assignments, reports |
| Refined Teacher role permissions | School admin panel |
| Staging deploy checklist | Student join-by-code |

### Backend (Strapi)

**2.1 Teacher permissions audit**

- Document current Teacher role (bootstrap copies `authenticated` permissions today — see `src/index.js`).
- Add explicit permissions only for endpoints teachers need in Phase 2–4:
  - `GET /institutions/validate-email-domain` (public — already exists)
  - `GET /users/me` with `populate=institution`
  - Future classroom routes (grant in Phase 3, stub policies now)
- Add policy helpers in `src/utils/` or `src/policies/`:
  - `is-teacher.js` — `ctx.state.user.account_type === 'teacher'`
  - `same-institution.js` — caller and target user share `institution`

**2.2 User API — teacher-safe `/users/me`**

- Ensure `account_type` and `institution` are returned on login/register and `/users/me`.
- Teachers must not receive `is_admin` capabilities unless explicitly set.

**2.3 Staging / production checklist**

- Run Phase 1 migrations on staging.
- Set `allowed_email_domains` on real institutions (Strapi Admin).
- Confirm `GET /api/institutions/validate-email-domain` is **public** (no 403).
- Seed at least one test institution per school domain.

### Flutter

**2.4 Main navigation branch**

- On `MainScreen` init, read `UserSession.isTeacher` (already in `token_storage` / `auth_service`).
- **Teacher tabs** (replace student Activity / Topics / Practice):
  1. **Classes** — placeholder → Phase 3 list
  2. **Profile** — existing profile tabs, teacher variant
- **Student tabs** — unchanged.
- Pattern: mirror `_isAdmin` branch in `app_start.dart` (`_tabs`, index clamping).

**2.5 Teacher home placeholder**

- New screen: `lib/screens/teacher/teacher_home_screen.dart`
- Shows: school name (from `institution`), welcome message, “Create a class” CTA (disabled until Phase 3).

**2.6 Teacher profile**

- On `ProfileAccountTab`: if teacher, show institution name + “Lehrer / Teacher” badge.
- Hide student-only items if irrelevant (e.g. parent share tab optional).

**2.7 Locales**

- Add keys under `teacher.*` in `en.json` / `de.json` (home title, empty-state, badge).

### Exit criteria

- [ ] Teacher registers → lands on teacher home (not student Topics tab).
- [ ] Student register/login → unchanged student UI.
- [ ] Teacher profile shows linked institution.
- [ ] Staging validate-email-domain returns 200 for configured domains.

### Suggested files

```
strapi-math/src/policies/is-teacher.js
strapi-math/src/policies/same-institution.js
fluentdeck-f/lib/screens/teacher/teacher_home_screen.dart
fluentdeck-f/lib/app_start.dart          (teacher tab branch)
fluentdeck-f/assets/locales/en.json      (teacher.* keys)
```

---

## Teacher accounts — Phase 3

**Goal:** Teachers create **classrooms**; students join with an **invite code**. Foundation for roster and analytics.

### Data model — `Classroom`

New collection type `api::classroom.classroom`:

| Field | Type | Notes |
|---|---|---|
| `name` | string | e.g. `7a Mathe 2026` |
| `grade` | string | optional, e.g. `7`, `10` — maps to `category-class` later |
| `invite_code` | string | unique, 6–8 chars, uppercase alphanumeric |
| `teacher` | relation → user | owner; must be `account_type: teacher` |
| `institution` | relation → institution | copied from teacher on create |
| `students` | relation M2M → users | only `account_type: student` |
| `archived` | boolean | default `false` |

Migration: `database/migrations/2026-XX-XX-create-classrooms.js` (+ link tables if needed).

User schema addition (optional):

| Field | Type | Notes |
|---|---|---|
| `classrooms_teaching` | O2M | inverse of `classroom.teacher` |
| `classrooms_enrolled` | M2M | inverse of `classroom.students` |

### Backend API

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/classrooms/mine` | Teacher | List teacher’s active classes |
| `POST` | `/classrooms` | Teacher | Create class; auto-set `institution`, generate `invite_code` |
| `PATCH` | `/classrooms/:id` | Teacher owner | Rename, archive |
| `POST` | `/classrooms/:id/regenerate-code` | Teacher owner | New invite code |
| `POST` | `/classrooms/join` | Student | Body: `{ "invite_code": "ABC123" }` |
| `POST` | `/classrooms/:id/leave` | Student | Leave class |
| `GET` | `/classrooms/:id` | Teacher owner or enrolled student | Class detail (no roster stats yet) |

**Validation rules**

- Only teachers create classes.
- Teacher must have `institution` set (from Phase 1 registration).
- Student join: code exists, class not archived, student not already in class.
- Max students per class (configurable, e.g. 40) — optional for v1.

**Policies**

- `is-teacher` on create/list mine.
- `is-class-owner` on PATCH / regenerate.
- `is-class-member-or-owner` on GET detail.

### Flutter

**3.1 Services**

- `lib/services/classroom_service.dart` — CRUD + join/leave.

**3.2 Teacher UI**

- Replace Phase 2 placeholder with **My classes** list.
- **Create class** dialog (name, optional grade).
- Class detail (Phase 3 minimal): name, invite code + copy/share button, student count, archive.

**3.3 Student UI**

- Profile or onboarding: **Join class** → enter invite code.
- Profile: list enrolled classes, leave action.

**3.4 Locales**

- `teacher.classes.*`, `student.join-class.*`

### Exit criteria

- [ ] Teacher creates class → receives invite code.
- [ ] Student joins with code → appears in class `students`.
- [ ] Wrong / expired code → clear error.
- [ ] Teacher cannot join as student; student cannot create class.
- [ ] Archived class rejects new joins.

### Suggested files

```
strapi-math/src/api/classroom/
fluentdeck-f/lib/services/classroom_service.dart
fluentdeck-f/lib/screens/teacher/teacher_classes_screen.dart
fluentdeck-f/lib/screens/teacher/teacher_class_detail_screen.dart
fluentdeck-f/lib/screens/profile/join_class_screen.dart
```

---

## Teacher accounts — Phase 4

**Goal:** Teacher opens a class and sees a **roster** with per-student activity snapshots (reuse existing stats APIs).

### Backend API

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/classrooms/:id/roster` | Teacher owner | Students + summary stats |
| `GET` | `/classrooms/:id/roster/:studentId` | Teacher owner | Single student detail |

**Roster item shape (per student)**

```json
{
  "id": 123,
  "username": "max7a",
  "points": 450,
  "last_active": "2026-06-02T18:30:00.000Z",
  "topics_completed": 12,
  "questions_answered_today": 8,
  "daily_goal": 10,
  "daily_goal_met": false
}
```

**Implementation notes**

- Reuse logic from existing handlers:
  - `get-user-status` — points, categories count, daily activity
  - `get-answers-stats` / `answered-questions` — today’s counts
  - `past-categories` — topics completed count
- Batch-query for all student IDs in class (avoid N+1).
- Enforce: caller is class `teacher`; each student is in `classroom.students`.
- Do **not** expose other teachers’ classes or unrelated students.

Optional query params for roster:

- `sort=last_active|points|username`
- `inactive_days=7` — filter students inactive > N days

### Flutter

**4.1 Teacher class detail → Roster tab**

- Tab 1: **Overview** (invite code, stats from Phase 3).
- Tab 2: **Students** — sortable list from `/roster`.
- Row: avatar/initial, username, points, last active, goal indicator (✓/○).
- Tap row → **Student snapshot** bottom sheet or screen.

**4.2 Student snapshot screen**

- Read-only view: points, topics completed, last 7 days activity (reuse `ProgressTab` chart component if possible).
- Link to full stats deferred to Phase 5.

**4.3 Empty / edge states**

- No students yet → “Share invite code” CTA.
- Student inactive 7+ days → subtle warning badge.

### Exit criteria

- [x] Roster loads for class with 1+ students.
- [x] Stats match what student sees on their own Status tab (same day).
- [x] Teacher A cannot load Teacher B’s roster.
- [x] Sort by last active works.
- [x] Empty class shows helpful empty state.

### Suggested files

```
strapi-math/src/api/classroom/controllers/classroom.js  (roster actions)
strapi-math/src/utils/class-roster-stats.js               (batch stats helper)
fluentdeck-f/lib/screens/teacher/teacher_class_roster_tab.dart
fluentdeck-f/lib/screens/teacher/teacher_student_snapshot_screen.dart
fluentdeck-f/lib/services/classroom_service.dart            (getRoster)
```

---

## Phase dependency overview

```text
Phase 1 (done) → Phase 2 (shell + permissions + staging)
                      ↓
                 Phase 3 (classrooms + join)
                      ↓
                 Phase 4 (roster + student snapshots)
```

| Phase | Backend | Flutter | Depends on |
|---|---|---|---|
| 2 | Policies, staging, `/users/me` fields | Teacher tabs, home, profile | Phase 1 |
| 3 | `Classroom` model + 6 endpoints | Class list, create, join | Phase 2 |
| 4 | Roster endpoints + stats batching | Roster tab, student snapshot | Phase 3 |

---

## Phase 2 & 3 — implementation status

**Phase 2 (done):** Teacher bottom nav (Classes + Profile), teacher badge on profile, school read-only for teachers, `is-teacher` policy, classroom auth helpers.

**Phase 3 (done):** `Classroom` content type, custom API routes, bootstrap permissions, Flutter class list/create/detail, student join/leave in profile.

**Phase 4 (done):** Roster endpoints with batched stats, teacher class **Students** tab (sortable list), student snapshot screen with 7-day activity chart.

**After pull — run:**

```bash
# restart Strapi (npm run develop) — creates classroom_members table
# hot restart Flutter app
```

### Membership approval workflow

| Step | Student | Teacher |
|---|---|---|
| Join with code | Creates `pending_join` request | Sees **Join requests** → Accept / Reject |
| Accepted | Becomes active member | Student appears in class list |
| Rejected | Can request again with same code | Request removed |
| Request leave | Sets `leave_pending` | Sees **Leave requests** → Approve leave / Deny |
| Leave approved | Removed from class | Student gone from list |
| Leave denied | Stays active member | — |
| Teacher removes member | Removed from class (or join request rejected) | **Remove** on active student / leave request |

**New API endpoints**

- `POST /api/classrooms/:id/members/:memberId/accept-join`
- `POST /api/classrooms/:id/members/:memberId/reject-join`
- `POST /api/classrooms/:id/members/:memberId/accept-leave`
- `POST /api/classrooms/:id/members/:memberId/deny-leave`
- `POST /api/classrooms/:id/members/:memberId/remove` — teacher removes a member (pending → rejected; active/leave_pending → left + removed from roster)

**Phase 4 — roster API**

- `GET /api/classrooms/:id/roster?sort=last_active|points|username&inactive_days=7`
- `GET /api/classrooms/:id/roster/:studentId` — single student snapshot with weekly activity

---

## Teacher accounts — Phases 5–7 (implemented)

### Phase 5 — Class progress analytics

| Method | Path | Description |
|---|---|---|
| GET | `/api/classrooms/:id/analytics?range=week\|month` | Class aggregates, daily activity, weak topics |

**Flutter:** Class detail tab **Progress** (7 / 30 day charts, weak-topic list).

### Phase 6 — Assignments & homework

| Method | Path | Description |
|---|---|---|
| GET | `/api/classrooms/:classroomId/assignments` | Teacher: list + completion % |
| POST | `/api/classrooms/:classroomId/assignments` | Create (targets: categories) |
| PATCH | `/api/assignments/:id` | Update / archive |
| GET | `/api/assignments/mine` | Student: open assignments + `blocked_category_ids` |
| GET | `/api/assignments/:id/progress` | Per-student completion table |

**Modes:** `informational` or `enforced` (locks topic until all target questions answered).

**Flutter:** Class tab **Work & reports** — create assignment; Topics tab — student banner + lock.

### Phase 7 — Reports & communication

| Method | Path | Description |
|---|---|---|
| GET | `/api/classrooms/:id/report-export` | CSV roster download |
| POST | `/api/classrooms/:id/send-report` | Email report to teacher (+ extra emails) |
| PATCH | `/api/classrooms/:id/report-settings` | `weekly_report_enabled`, `report_extra_emails` |

**Cron:** `sendWeeklyClassReports` — Mondays 08:00 Europe/Berlin for classes with weekly reports on.

**Migrations:**

```bash
node database/migrate.js 2026-06-04T10-00-00-create-assignments.js
node database/migrate.js 2026-06-04T11-00-00-classroom-report-settings.js
```

Restart Strapi after pull.

