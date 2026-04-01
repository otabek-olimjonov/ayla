import postgres from 'postgres'
import { readFileSync } from 'fs'

const regions = [
  'aws-0-us-east-1',
  'aws-0-us-west-1', 
  'aws-0-eu-central-1',
  'aws-0-eu-west-1',
  'aws-0-ap-southeast-1',
  'aws-0-ap-northeast-1',
]

const PROJECT = 'wsvldokpfovenivinidq'
const PASSWORD = 'TlUIpuprOZ05D6wW'

async function tryConnect(region) {
  const url = `postgresql://postgres.${PROJECT}:${PASSWORD}@${region}.pooler.supabase.com:5432/postgres`
  const sql = postgres(url, { ssl: 'require', max: 1, connect_timeout: 8 })
  try {
    const result = await sql`SELECT 1 AS ok`
    if (result[0]?.ok === 1) {
      console.log(`✓ Connected via ${region}`)
      return sql
    }
  } catch (e) {
    console.log(`✗ ${region}: ${e.message.slice(0, 60)}`)
    await sql.end({ timeout: 1 })
    return null
  }
}

let sql = null
for (const region of regions) {
  sql = await tryConnect(region)
  if (sql) break
}

if (!sql) {
  console.error('Could not connect to Supabase. Check connection.')
  process.exit(1)
}

const migration = readFileSync(
  new URL('../supabase/migrations/20260325000000_add_email_to_profiles.sql', import.meta.url),
  'utf8'
)

try {
  await sql.unsafe(migration)
  console.log('✓ Migration applied successfully!')
  
  // Verify
  const check = await sql`SELECT column_name FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'email'`
  if (check.length > 0) {
    console.log('✓ email column confirmed in profiles table')
    const count = await sql`SELECT COUNT(*) FROM public.profiles WHERE email IS NOT NULL`
    console.log(`✓ Backfilled ${count[0].count} profiles with email`)
  }
} catch (e) {
  console.error('Migration error:', e.message)
} finally {
  await sql.end()
}
