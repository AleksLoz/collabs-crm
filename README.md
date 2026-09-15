# Collabs — creator CRM

A single-file React app (no build step — React, ReactDOM, and `htm` load from CDN)
covering a dashboard, kanban pipeline, content calendar, and contacts table for
managing brand collaborations. Black/white/grey design, multi-currency pricing
converted to DKK, drag-and-drop everywhere.

`index.html` is the whole app. Data and login are backed by [Supabase](https://supabase.com)
(Postgres + auth + realtime) so the whole team sees the same, live data.

## Setup (one person does this once)

1. **Create a Supabase project** at [supabase.com](https://supabase.com) (free tier is enough).
2. **Run the schema.** Open the SQL editor in your project and run the contents of
   [`supabase/schema.sql`](supabase/schema.sql). This creates the five tables
   (`contacts`, `collabs`, `deliverables`, `ideas`, `tasks`) plus `settings`,
   and locks them so only signed-in users can read or write.
3. **Turn off public sign-ups.** In Supabase: Authentication -> Sign In / Providers,
   turn **off** "Allow new users to sign up". This app has no self-serve sign-up
   screen, but that setting also blocks anyone from creating an account directly
   against the API — important since the anon key is public and the app itself
   will likely be hosted at a public URL. Team members are added by hand (see
   "Inviting coworkers" below).
4. **Get your API keys.** Project Settings -> API -> copy the Project URL and the
   `anon` `public` key (or "Publishable key" on newer projects).
5. **Configure the app.** Copy `config.example.js` to `config.js` and paste in
   those two values:
   ```bash
   cp config.example.js config.js
   ```
   `config.js` is gitignored — each place this runs (your machine, a teammate's,
   a host) needs its own copy. The anon/publishable key is public by design
   (safe in client code); real access control lives in the Row Level Security
   policies in `schema.sql`, not in hiding this key.
6. **Open `index.html`** in a browser (or serve the folder with any static
   server). Sign in with the account you create for yourself in the next step.

## Inviting coworkers

Login is email + password — there's no magic link and no self-serve sign-up,
so every account is created by hand:

1. In Supabase: Authentication -> Users -> **Add user**
2. Enter their email and set a password (check "Auto Confirm User" if shown)
3. Tell them the password out of band (Slack, in person — not email)

Anyone who signs in gets full read/write access to the shared board — this is
a small internal CRM, not a multi-tenant product, so there's no per-user
permission tier. Because login never sends an email, there's no rate limit to
worry about as more people start using it.

## Hosting

This is a static file with no build step, so any static host works once
`config.js` is set: [Vercel](https://vercel.com), [Netlify](https://netlify.com),
or GitHub Pages (Settings -> Pages -> deploy from the `main` branch — note Pages
requires the repo to be public, or GitHub Pro/Enterprise for a private one).

## What's in this repo

- `index.html` — the whole app (UI, state, and the Supabase data layer in `useStore()`).
- `supabase/schema.sql` — table definitions + RLS policies, run once per project.
- `config.example.js` — template for `config.js` (your Supabase URL + anon key).

## History

This started as a Claude.ai Artifact using `window.claude.use("db")` for
storage, which only works inside Claude.ai. This version replaces that with
real Supabase auth and a Postgres backend so it works anywhere and the team
can actually share data.
