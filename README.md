# FitLedger

A responsive gym, diet, and personal money tracker built as a single-page site in `index.html`.

## Supabase setup

1. Open the Supabase project at `https://koiwocybjmrvrxopvckd.supabase.co`.
2. In **SQL Editor**, run the full contents of [`supabase-setup.sql`](supabase-setup.sql). It creates nine tables, adds user-scoped RLS policies, and seeds the 7-day workout, diet profile, daily meal schedule, and weekly meal variations. Workout and diet pages fetch this content from Supabase after login. Money entries, workout/meal check-ins, and personal plan edits are stored per user.
   If the `transactions` table already exists from an earlier setup, run [`borrowed-migration.sql`](borrowed-migration.sql) to allow the additional `borrowed` entry type.
   To enable permanent and date-only workout/diet edits on an existing database, also run [`plan-editor-migration.sql`](plan-editor-migration.sql).
   To enable the returned/repaid checkbox for lent and borrowed entries on an existing database, run [`loan-settlement-migration.sql`](loan-settlement-migration.sql).
3. In **Authentication → Providers → Email**, leave the Email provider enabled and turn **Confirm email** off. The app presents username/password only, and uses an internal synthetic email address with Supabase Auth to provide secure accounts without sending confirmation emails. Usernames are 3–24 characters: letters, numbers, `_`, `-`, or `.`. Passwords must be at least 6 characters. If you already hit the email rate limit, turning confirmation off prevents new confirmation sends, but Supabase may still require waiting for its current rate-limit window to reset. If an earlier attempt created an unconfirmed `username@fitledger.invalid` user, confirm that user in **Authentication → Users** before logging in.
4. The project URL and publishable key are set in the module script in `index.html`. A publishable key is intended for browser use; never put a service-role key or database password in this file.

## Run locally

Serve this folder over HTTP (ES modules do not work reliably from a `file://` URL). For example:

```sh
python3 -m http.server 8000
```

Then open `http://localhost:8000`.

## Features

- Username/password sign-up, login, and logout (Supabase Auth-backed)
- Expense, income, money lent/borrowed, and repayment history
- Mark lent money as returned or borrowed money as repaid; track pending balances
- Seven-day workout plan with daily exercise check-ins
- Daily meal plan with meal check-ins
- Overview shows today's weekday-matched workout and meal schedule
- Monthly finance, workout, and meal progress report with print-to-PDF export
- Account-scoped cloud storage through Supabase
