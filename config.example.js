/* Copy this file to config.js and fill in your Supabase project's values.
   Get them from: Supabase dashboard -> Project Settings -> API.
   The anon key is a public, publishable key -- it's safe to ship in client
   code. Access to data is controlled by the Row Level Security policies in
   supabase/schema.sql, not by hiding this key. */
window.COLLABS_CONFIG = {
  SUPABASE_URL: "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-ANON-PUBLIC-KEY",
  // Who can see the whole To do (columns, Ta da, the switch, archived tasks).
  // This is the signed-in Supabase user's email. Leave it unset to keep the
  // default, contact@byggeligt.com. Set TADA_OWNER_ID to that user's UUID
  // instead to pin the account even if the email changes (the id wins when
  // it is set). The database policy in supabase/schema.sql has to name the
  // same person, or their To do will come back empty.
  TADA_OWNER_EMAIL: "contact@byggeligt.com"
};
