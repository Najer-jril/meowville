// Menghapus akun user yang sedang login beserta file Storage miliknya.
//
// Urutan:
// 1. Verifikasi JWT user.
// 2. assert_can_delete_account() dijalankan atas nama user (reservasi aktif,
//    admin terakhir).
// 3. Hapus file: avatars, cat-photos, payment-proofs di folder user, dan foto
//    laporan harian untuk reservasi milik user.
// 4. Hapus auth user. Data di tabel public ikut terhapus lewat ON DELETE CASCADE.
//
// room-photos tidak disentuh: foto tipe kamar milik hotel, bukan milik admin
// yang meng-upload. Foto laporan yang di-upload sitter tetap ada selama
// laporannya milik owner lain.

import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2.49.4';

const OWN_BUCKETS = ['avatars', 'cat-photos', 'payment-proofs'];
const REPORT_BUCKET = 'report-photos';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

async function listFolder(admin: SupabaseClient, bucket: string, folder: string) {
  const paths: string[] = [];
  for (let offset = 0; ; offset += 1000) {
    const { data, error } = await admin.storage.from(bucket).list(folder, { limit: 1000, offset });
    if (error) throw error;
    paths.push(...data.map((f) => `${folder}/${f.name}`));
    if (data.length < 1000) return paths;
  }
}

async function removeAll(admin: SupabaseClient, bucket: string, paths: string[]) {
  for (let i = 0; i < paths.length; i += 100) {
    const { error } = await admin.storage.from(bucket).remove(paths.slice(i, i + 100));
    if (error) throw error;
  }
}

// Kolom photo berisi "report-photos/<uid>/<file>". Data lama bisa berupa URL
// publik (.../object/public/report-photos/<uid>/<file>).
function reportPhotoPath(photo: string): string | null {
  const prefix = `${REPORT_BUCKET}/`;
  if (photo.startsWith(prefix)) return photo.slice(prefix.length);
  const marker = `/${prefix}`;
  const i = photo.indexOf(marker);
  return i >= 0 ? decodeURIComponent(photo.slice(i + marker.length)) : null;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ message: 'Method not allowed' }, 405);

  const url = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const authHeader = req.headers.get('Authorization') ?? '';
  const asUser = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userError } = await asUser.auth.getUser();
  const user = userData?.user;
  if (userError || !user) return json({ message: 'Sesi berakhir, silakan login ulang' }, 401);

  const { error: checkError } = await asUser.rpc('assert_can_delete_account');
  if (checkError) return json({ message: checkError.message }, 409);

  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  try {
    for (const bucket of OWN_BUCKETS) {
      await removeAll(admin, bucket, await listFolder(admin, bucket, user.id));
    }

    const { data: reports, error: reportError } = await admin
      .from('daily_reports')
      .select('photo, reservation:reservations!inner(owner_id)')
      .eq('reservation.owner_id', user.id)
      .not('photo', 'is', null);
    if (reportError) throw reportError;
    const reportPaths = (reports ?? [])
      .map((r) => reportPhotoPath(r.photo as string))
      .filter((p): p is string => p !== null);
    await removeAll(admin, REPORT_BUCKET, reportPaths);

    const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
    if (deleteError) throw deleteError;
  } catch (e) {
    console.error('delete-account failed', user.id, e);
    return json({ message: 'Gagal menghapus akun. Coba lagi beberapa saat.' }, 500);
  }

  return json({ ok: true });
});
