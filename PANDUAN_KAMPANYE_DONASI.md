# Panduan Penerapan: Alur Kampanye & Donasi ITSbisa

Dokumen ini menjelaskan cara memasang fitur **Proses A (kampanye)** dan **Proses B (donasi dana)** ke proyek Flutter ITSbisa, berurutan dari database sampai aplikasi.

Cakupan: F03 Beranda/cari/kategori, F04 Detail, F05 Pengajuan, F06 Verifikasi admin, F07 Donasi + Midtrans, F08 Riwayat + lanjutkan pembayaran, F10 Penutupan otomatis, F11 Pencairan, F12 Laporan.
Tidak termasuk: donasi barang (tabelnya belum ada di SQL v1), kabar terbaru versi penggalang (F09, hanya ditampilkan), lencana, notifikasi UI, kelola kategori/pengguna.

---

## Langkah 1 — Database Supabase

1. Pastikan `itsbisa_supabase_v1.sql` sudah dijalankan di proyek Supabase.
2. Buka **Dashboard → SQL Editor**, tempel isi `supabase/migrations/002_alur_kampanye_donasi.sql`, lalu **Run** (sekali saja).
   File ini menambah: RPC daftar kampanye, pembuatan donasi, pemrosesan notifikasi Midtrans, penutupan kampanye, pencairan, laporan, serta 4 bucket Storage beserta policy-nya.
3. Aktifkan penutupan otomatis (F10):
   - **Database → Extensions** → aktifkan `pg_cron`.
   - Di SQL Editor jalankan:
     ```sql
     select cron.schedule('itsbisa-close-campaigns', '*/15 * * * *', $$select public.close_campaigns()$$);
     ```
4. Jadikan satu akun sebagai admin (akun harus sudah daftar dan verifikasi email ITS):
   ```sql
   update public.profiles set role = 'admin'
   where id = (select id from auth.users where email = 'email-admin@its.ac.id');
   ```

## Langkah 2 — Midtrans Sandbox

1. Daftar/masuk di <https://dashboard.sandbox.midtrans.com>.
2. **Settings → Access Keys**: salin **Server Key** (awalan `SB-Mid-server-`). Jangan dimasukkan ke kode Flutter.
3. **Settings → Payment → Notification URL**, isi:
   ```
   https://<project-ref>.supabase.co/functions/v1/midtrans-notification
   ```
   `<project-ref>` ITSbisa ada di URL Supabase pada `lib/main.dart`.

## Langkah 3 — Edge Functions (Git Bash)

Butuh Node.js. Supabase CLI dijalankan lewat `npx` (CLI tidak mendukung `npm install -g`).

```bash
cd /d/ITSbisa-06-a                      # folder proyek (berisi folder supabase/)
npx supabase login
npx supabase link --project-ref <project-ref>

# kunci Midtrans (disimpan di Supabase, bukan di aplikasi)
npx supabase secrets set MIDTRANS_SERVER_KEY=SB-Mid-server-xxxx MIDTRANS_IS_PRODUCTION=false

# deploy dua fungsi
npx supabase functions deploy create-donation --no-verify-jwt
npx supabase functions deploy midtrans-notification --no-verify-jwt
```

Tanpa CLI: buat fungsi lewat **Dashboard → Edge Functions → Deploy a new function → Via Editor**, salin `index.ts` masing-masing beserta `_shared/env.ts` (ubah import `../_shared/env.ts` menjadi `./env.ts`), matikan **Verify JWT**, lalu isi secret di **Edge Functions → Secrets**.

| Fungsi | Dipanggil oleh | Tugas |
|---|---|---|
| `create-donation` | Aplikasi (`DonationService.createDonation`) | Cek pengguna → RPC `create_donation` → buat transaksi Snap → simpan `redirect_url` |
| `midtrans-notification` | Server Midtrans | Cek `signature_key` → ambil status resmi ke API Midtrans → RPC `apply_payment_notification` |

`--no-verify-jwt` aman karena `create-donation` memeriksa sesi sendiri, dan `midtrans-notification` memeriksa signature.

## Langkah 4 — Package Flutter

Di `pubspec.yaml` (sudah ditambahkan):
```yaml
  url_launcher: ^6.3.1
  file_picker: ^13.4.1
```
Lalu:
```bash
flutter pub get
```
`android/app/src/main/AndroidManifest.xml` sudah ditambah izin `INTERNET` dan `<queries>` untuk membuka halaman Midtrans.

> file_picker v13 memakai `FilePicker.pickFile()`. Kalau tim memakai versi lama (v8–v12), ubah **hanya** `lib/services/file_pick_service.dart` (contoh kode lama ada di komentar file itu).

## Langkah 5 — Urutan membuat / menyalin file Dart

Tampilan mengikuti frame Figma **S02–S08 Canonical UI** (daftar lengkap di `DESIGN.md` bagian 5).
Ikuti urutan ini supaya setiap file sudah punya dependensinya. **Baru** = file baru, **Ubah** = file lama yang diganti.

| # | File | Status | Isi |
|---|---|---|---|
| 1 | `lib/utils/parse.dart` | Baru | Baca angka/tanggal dari JSON Supabase |
| 2 | `lib/utils/formatters.dart` | Ubah | + format tanggal, `parseRupiah`, input pemisah ribuan |
| 3 | `lib/theme/app_colors.dart` | Ubah | Warna Figma (BiruMuda #0CC0D9) + warna status |
| 4 | `lib/models/campaign.dart` | Ubah | Model dari RPC `get_campaigns`, status kampanye |
| 5 | `lib/models/campaign_extras.dart` | Baru | Kategori, donatur, kabar, laporan, pencairan, review, rekening |
| 6 | `lib/models/donation.dart` | Baru | Donasi + transaksi untuk Riwayat |
| 7 | `lib/services/supabase_errors.dart` | Baru | Pesan error yang ramah |
| 8 | `lib/services/file_pick_service.dart` | Baru | Pilih foto/dokumen |
| 9 | `lib/services/storage_service.dart` | Baru | Upload ke bucket Storage |
| 10 | `lib/services/campaign_service.dart` | Baru | Daftar, detail, ajukan, pencairan, laporan |
| 11 | `lib/services/donation_service.dart` | Baru | Donasi, buka Midtrans, cek status, riwayat |
| 12 | `lib/services/admin_service.dart` | Baru | Verifikasi kampanye & proses pencairan |
| 13 | `lib/widgets/its_ui.dart` | Baru | Komponen Canonical UI (halaman, kartu, upload) |
| 14 | `lib/widgets/campaign_cover.dart`, `status_chip.dart`, `async_states.dart` | Baru | Foto sampul, label status, error/kosong |
| 15 | `lib/widgets/payout_sheet.dart`, `amount_sheet.dart` | Baru | Isi rekening; sheet "Tambahkan donasi" |
| 16 | `lib/widgets/campaign_card.dart` | Ubah | Pakai foto sampul asli |
| 17 | `lib/screens/donasi/donasi_page.dart` | Ubah | S02.02 / S02.03 |
| 18 | `lib/screens/campaign/campaign_detail_page.dart` | Ubah | Detail + kartu Kelola Kampanye |
| 19 | `lib/screens/campaign/payment_status_page.dart` | Baru | S05.04 |
| 20 | `lib/screens/campaign/donation_form_page.dart` | Ubah | S05.01 |
| 21 | `lib/screens/campaign/donation_success_page.dart` | Baru | 101:5873 |
| 22 | `lib/screens/riwayat/riwayat_page.dart` | Ubah | S05.06 |
| 23 | `lib/screens/riwayat/donation_detail_page.dart` | Baru | S05.07 |
| 24 | `lib/screens/campaign/create_campaign_type_page.dart` | Baru | S03.01 |
| 25 | `lib/screens/campaign/submit_campaign_page.dart` | Ubah | S03.02 |
| 26 | `lib/screens/campaign/submit_review_page.dart` | Baru | S03.06 |
| 27 | `lib/screens/campaign/my_campaigns_page.dart` | Baru | S03.08 |
| 28 | `lib/screens/campaign/manage_campaign_page.dart` | Baru | S03.09 + S07.04 |
| 29 | `lib/screens/campaign/disbursement_page.dart` | Baru | S08.01 / S08.02 |
| 30 | `lib/screens/campaign/fund_report_page.dart`, `fund_report_preview_page.dart` | Baru | S08.06 / S08.07 |
| 31 | `lib/screens/admin/admin_page.dart` | Baru | S04.01, S04.02, S08.03 |
| 32 | `lib/screens/admin/admin_review_page.dart`, `admin_decision_page.dart` | Baru | S04.03 / S04.05 |
| 33 | `lib/screens/admin/admin_disbursement_review_page.dart` | Baru | S08.04 |
| 34 | `lib/routes/app_routes.dart` | Ubah | Semua rute baru |
| 35 | `lib/screens/home/home_page.dart`, `main_shell.dart`, `profil/profil_page.dart` | Ubah | Data Supabase, pencarian, menu Panel Admin |
| 36 | `lib/data/dummy_campaigns.dart` | **Hapus** | Tidak dipakai lagi |

Setelah semua file masuk:
```bash
dart format lib
flutter analyze
flutter run
```

## Langkah 6 — Uji alur dari awal sampai akhir

Siapkan 3 akun email ITS: **Penggalang**, **Donatur**, **Admin** (Langkah 1.4).

1. **Penggalang**: Home → Galang Dana → Pilih Bantuan Dana → isi Informasi Kampanye (termasuk rekening & dokumen) → Tinjau Pengajuan → Kirim.
   Otomatis terbuka Kampanye Saya dengan status *Menunggu Verifikasi*.
2. **Admin**: Profil → Panel Admin → Lihat Pengajuan → Tinjau → Lihat Dokumen → Setujui Kampanye → Simpan Keputusan.
3. **Donatur**: kampanye muncul di Home/Donasi → Detail → Donasi → pilih nominal → Lanjutkan Pembayaran → Buka Pembayaran.
   Di halaman Midtrans pilih misalnya **BCA Virtual Account**, salin nomor VA, lalu bayar lewat simulator <https://simulator.sandbox.midtrans.com>.
   Kembali ke aplikasi: halaman berubah ke **Donasi Berhasil**, perolehan kampanye bertambah.
   Coba juga tutup halaman pembayaran tanpa membayar → Riwayat → Lihat Detail Donasi → **Lanjutkan Bayar**.
4. Kampanye **Selesai** saat target tercapai (langsung) atau tenggat lewat (pg_cron tiap 15 menit; untuk uji cepat jalankan `select public.close_campaigns();`).
5. **Penggalang**: Riwayat → Lihat Kampanye Saya → Kelola Kampanye → Ajukan Pencairan → Kirim Pengajuan Pencairan.
6. **Admin**: Panel Admin → Lihat Pencairan → Periksa → coba **Minta Perbaikan**; setelah penggalang Kirim Ulang → unggah bukti transfer → **Konfirmasi Dana Dicairkan**. Status kampanye: *Dana Dicairkan*.
7. **Penggalang**: Kelola Kampanye → Buat Laporan → isi + bukti → Tinjau Laporan → Publikasikan Laporan. Status: *Dilaporkan*; laporan tampil di detail untuk semua pengguna.

## Catatan

- **Aturan bisnis ada di database**, bukan hanya di aplikasi: minimal Rp5.000, hanya akun ITS terverifikasi, donasi hanya ke kampanye aktif, perolehan hanya bertambah dari notifikasi settlement yang sah, pencairan ditolak jika masih ada pembayaran tertunda.
- **Mendesak** = ditandai admin (`is_urgent`) atau kampanye aktif dengan tenggat ≤ 7 hari.
- `test/widget_test.dart` bawaan template masih menguji "Counter" dan tidak relevan; hapus atau ganti sebelum menjalankan `flutter test`.
- Tampilan mengikuti frame Figma S02–S08 (Canonical UI). Pilihan Barang di S03.01 ditampilkan tetapi dinonaktifkan; Kelola Kabar Terbaru (S07.01–S07.02) belum dibuat.
