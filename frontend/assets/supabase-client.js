// ============================================================
// ⚠️ ИНРО ПУР КУН: аз Supabase Dashboard → Project Settings → API
// ============================================================
const SUPABASE_URL = "https://zflptdldjpqaetkfraid.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpmbHB0ZGxkanBxYWV0a2ZyYWlkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1MTg4NDcsImV4cCI6MjEwMjA5NDg0N30.NXE5X_Ojm_YSc32LuQz_nlwM3tY8pO_fbj5yBznYMTo";

const sb = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ---------- Хондани барномаҳо (ҷамъиятӣ, published=true) ----------
async function fetchApps({ section = null, search = "" } = {}) {
  let q = sb.from("apps").select("*").eq("published", true).order("created_at", { ascending: false });
  if (section) q = q.eq("section", section);
  const { data, error } = await q;
  if (error) { console.error(error); return []; }
  if (!search) return data;
  const s = search.toLowerCase();
  return data.filter(a =>
    a.name_tj?.toLowerCase().includes(s) ||
    a.name_ru?.toLowerCase().includes(s) ||
    a.tags?.some(t => t.toLowerCase().includes(s))
  );
}

async function fetchAppBySlug(slug) {
  const { data, error } = await sb.from("apps").select("*").eq("slug", slug).single();
  if (error) { console.error(error); return null; }
  return data;
}

async function incrementDownload(id, current) {
  await sb.from("apps").update({ downloads_count: (current || 0) + 1 }).eq("id", id);
}
