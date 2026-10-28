# Personal Finance Tracker

An app for keeping track of income, expenses and budgets. Built by our team for the HITS course project.

**Stack:** C# / ASP.NET Core (.NET 10) backend, Flutter frontend, PostgreSQL database.

## What's where

```
backend/     ASP.NET Core API + xUnit tests
frontend/    Flutter app + widget tests
docs/        Definition of Done, diagrams, notes
docker-compose.yml
.env.example
```

## Getting started

You need Git and Docker Desktop. That's enough to run the whole thing.

```bash
git clone https://github.com/<owner>/finance-tracker-hits.git
cd finance-tracker-hits
cp .env.example .env
docker compose up --build
```

- App: http://localhost:8080
- API: http://localhost:5000/api/health
- Database: localhost:5432 (login details are in your `.env`)

`Ctrl+C` stops it. `docker compose down -v` stops it and wipes your local database.

The first build is slow. If someone changes a Dockerfile, a `.csproj` or `pubspec.yaml`, run `docker compose up --build` again after pulling.

Don't commit your `.env`. It's in `.gitignore` for a reason. If you add a new setting, add it to `.env.example` too so everyone else gets it.

## Working on the code

Docker is fine for running the app, but for actual development you'll want the [.NET 10 SDK](https://dotnet.microsoft.com/download) and/or [Flutter](https://docs.flutter.dev/get-started/install) installed, depending on which side you're on. Start just the database with `docker compose up db`, then:

```bash
# backend (runs on localhost:5000)
cd backend
dotnet run --project src/FinanceTracker.Api

# frontend
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
```

On the Android emulator, use `http://10.0.2.2:5000` instead of localhost.

## Tests

```bash
cd backend && dotnet test
cd frontend && flutter test
```

Run them before you push. GitHub Actions runs them anyway on every push and PR, and a PR with failing checks doesn't get merged.

## How we work

- Nobody pushes straight to `main`.
- Every task has an issue on the board. Make a branch for it: `feature/12-add-transactions`, `fix/15-login-crash`.
- When you're done, open a pull request into `main` and ask someone to review it. It needs one approval and green checks.
- Keep PRs small. One task per PR.
- Commit messages say what the commit does: `Add transaction list endpoint (#12)`, not `fixes` or `update`.
- Pull `main` often so you're not fixing a week of merge conflicts at once.
- Something done means it meets the Definition of Done in `docs/`.

## Team

| Name | Role |
|------|------|
|      |      |
