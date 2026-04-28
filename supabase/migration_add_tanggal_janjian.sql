alter table public.pasien
add column if not exists tanggal_janjian date;

create unique index if not exists idx_kehadiran_pasien_tanggal
on public.kehadiran_pasien (id_pasien, tanggal_hadir);
