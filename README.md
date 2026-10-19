# QuitCapping — Anti-Procrastination & Peer Accountability Platform

QuitCapping is an anti-procrastination mobile application and backend ecosystem where users build AI-driven daily roadmaps, submit concrete photo proof for tasks, and must peer-review 5 submissions from others each day ("Give-to-Get Engine") before their own proof is judged by the community.

---

## 🏗️ Architecture & Tech Stack

```text
QuitCappingProject/
├── backend/                  # NestJS TypeScript API (Modular Architecture)
│   ├── src/
│   │   ├── auth/             # JWT, bcrypt, AuthGuards, Register/Login DTOs
│   │   ├── goals/            # Gemini AI Service (Structured JSON), Roadmap CRUD
│   │   ├── tasks/            # Daily micro-tasks, completion checking
│   │   ├── submissions/      # Multer & Cloudinary upload, Give-to-Get state machine
│   │   ├── reviews/          # Quota engine, random blind swipe feed, consensus resolution
│   │   ├── common/           # Custom decorators, MongoExceptionFilter, date utils
│   │   └── database/schemas/ # Mongoose Schemas (User, Goal, Task, Submission, Review)
│   └── test/                 # Anti-Cheat & Give-to-Get Unit & E2E Test Suite
│
└── mobile/                   # Flutter Mobile Client (Clean Architecture, Feature-First)
    └── lib/
        ├── core/             # Dio client, JWT interceptor, theme, tokens
        └── features/
            ├── auth/         # Login, Register, AuthController (Riverpod)
            ├── roadmap/      # AI Goal generator, day-by-day micro-tasks timeline
            ├── proof/        # Camera/Gallery photo upload with concrete evidence guidelines
            ├── reviews/      # Tinder-style swipe deck, 5-review Give-to-Get progress bar
            └── profile/      # Streak counter, quota badge, active goal stats
```

---

## ⚡ Core Logic & Anti-Cheat Rules

1. **AI Goal Generation (Google Gemini Structured JSON):**
   - User submits target goal, current skill level, and duration.
   - Backend calls Gemini with structured JSON Schema to produce 3-5 daily micro-tasks per day, each with an unambiguous `evidencePrompt` detailing what photograph to take.

2. **Give-to-Get Engine:**
   - User uploads photo proof -> Submission status = `pending_quota`.
   - The submission remains hidden from the global queue until the user completes $\ge 5$ peer reviews on that calendar day (`dailyReviewsDone >= 5`).
   - Upon completing review #5, the user's pending submissions automatically transition to `in_queue`.
   - Midnight UTC resets `dailyReviewsDone` to 0 daily.

3. **Peer Review & Consensus Resolution:**
   - 5 distinct random peers evaluate each submission (Swipe Right = Approve, Swipe Left = Reject).
   - $\ge 3$ Upvotes $\rightarrow$ Status = `approved`, task marked complete (`isCompleted = true`), streak updated.
   - $\ge 3$ Downvotes $\rightarrow$ Status = `rejected`, task must be retried.
   - **Blind Review:** Reviewers never see the author's name, user ID, or avatar.
   - **Self-Review Prevention:** Users can never fetch or review their own submissions (`userId != currentUserId`).
   - **Idempotency:** Unique compound index `{ submissionId: 1, reviewerId: 1 }` strictly forbids double voting.

---

## 🚀 Getting Started

### 1. Backend Setup (NestJS + MongoDB)

```bash
cd backend

# 1. Install dependencies
npm install

# 2. Configure environment (.env)
cp .env.example .env
# Edit .env with your MongoDB URI, JWT secret, and optional Gemini/Cloudinary keys

# 3. Run unit tests
npm test

# 4. Start backend development server
npm run start:dev
```
The backend starts at `http://localhost:3000`.

### 2. Mobile Setup (Flutter)

```bash
cd mobile

# 1. Get packages
flutter pub get

# 2. Analyze code (Clean 0 issues)
flutter analyze

# 3. Run Flutter tests
flutter test

# 4. Launch app on connected device or simulator
flutter run
```

---

## 🧪 Verified Test Coverage

- `src/reviews/reviews.service.spec.ts`:
  - Anti-Cheat: Self-Review Prevention (`ForbiddenException`)
  - Anti-Cheat: Review Idempotency (`ConflictException`)
  - Peer Review Vote Resolution ($\ge 3$ upvotes $\rightarrow$ APPROVED & task completed)
  - Peer Review Vote Resolution ($\ge 3$ downvotes $\rightarrow$ REJECTED & retry required)
  - Give-to-Get Engine: Auto-unlock of pending submissions upon 5th review
- `src/submissions/submissions.service.spec.ts`:
  - `pending_quota` assignment when quota not yet satisfied
  - Direct `in_queue` assignment when quota is already satisfied
  - Access control: cannot submit evidence for another user's task
- `mobile/test/widget_test.dart`:
  - ProviderScope & state initialization smoke tests
