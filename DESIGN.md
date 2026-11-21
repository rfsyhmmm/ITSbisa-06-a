# DESIGN.md: Panduan Tampilan ITSbisa

Acuan supaya tampilan Flutter sama dengan Figma.
Figma: https://www.figma.com/design/FssnwtlX909JctcQ1QVUOm/ITSBisa

**Aturan utama:** jangan menulis warna atau gaya langsung di halaman.
Pakai `AppColors` (`lib/theme/app_colors.dart`) dan komponen di `lib/widgets/`.
Kalau butuh warna atau komponen baru, tambahkan di sana dulu, lalu catat di file ini.

---

## 1. Warna

| Nama di kode | Hex | Dipakai untuk |
|---|---|---|
| `AppColors.primary` | `#0CC0D9` | Tombol utama, menu bawah aktif, progress bar, gelombang |
| `AppColors.primaryLight` | `#E7F9FB` | Latar Login/Register/Splash, latar ikon |
| `AppColors.navy` | `#0B2A5B` | Logo, tombol **Donasi** di detail kampanye, ikon header |
| `AppColors.background` | `#F7FBFC` | Latar halaman umum |
| `AppColors.surface` | `#FFFFFF` | Kartu, kolom input, AppBar |
| `AppColors.textPrimary` | `#1F2933` | Teks utama |
| `AppColors.textSecondary` | `#8A94A6` | Teks keterangan, hint, menu bawah tidak aktif |
| `AppColors.border` | `#DDE3EA` | Garis kolom input, latar progress bar |
| `AppColors.verified` | `#2F80ED` | Ikon centang akun terverifikasi |

Aset dari Figma (`assets/images/`): `wave_top.png` (Login/Register), `wave_bottom.png` (Splash), `logo_itsbisa.png` (Splash, header Home). Semua masih export 1x; export ulang 3x supaya lebih tajam.

## 2. Bentuk dan jarak

| Elemen | Nilai |
|---|---|
| Sudut kolom input dan tombol | 12 |
| Sudut kartu (kampanye, kartu login) | 16 |
| Tinggi tombol utama | 48 (tombol kecil di kartu: 38) |
| Jarak tepi halaman | 16 sampai 20 |
| Jarak antar kolom form | 16 |
| Lebar kartu kampanye di daftar menyamping | 190 |

## 3. Teks

| Jenis | Ukuran | Tebal |
|---|---|---|
| Judul besar (LOGIN, Selamat Datang!) | 32 | Bold (w700) |
| Judul bagian (Kampanye Aktif) | 17 | SemiBold (w600) |
| Judul kartu | 14 | SemiBold (w600) |
| Isi | 14 | Regular |
| Keterangan kecil | 12 | Regular |

Font Figma belum dipasang (masih font bawaan Android). Kalau mau sama persis,
cek nama font di panel kanan Figma, lalu pasang lewat folder `assets/fonts` dan `pubspec.yaml`.

## 4. Komponen (`lib/widgets/`)

| Komponen | File | Contoh pemakaian |
|---|---|---|
| Tombol utama | `primary_button.dart` | `PrimaryButton(label: 'Donasi', onPressed: ...)`; tombol navy: `color: AppColors.navy` |
| Kolom input + label | `app_text_field.dart` | `AppTextField(label: 'Email ITS', hint: 'Your email')`; password: `isPassword: true` |
| Kartu kampanye | `campaign_card.dart` | `CampaignCard(campaign: c, onTap: ..., onDonate: ...)` |
| Judul bagian | `section_header.dart` | `SectionHeader(title: 'Kampanye Aktif', onSeeAll: ...)` |
| Gelombang | `wave_background.dart` | `WaveBackground()`; gelombang bawah: `WaveBackground(atBottom: true)` |
| Isi sementara | `placeholder_view.dart` | Untuk halaman yang belum dikerjakan |

## 5. Daftar halaman

| Figma | Rute | File | Status |
|---|---|---|---|
| Splash | `/` (halaman pertama) | `screens/splash/splash_page.dart` | Sesuai Figma |
| Login / Register | `/masuk` (belum login) | `screens/auth/auth_page.dart` | Sesuai Figma |
| Home | `/masuk` (sudah login), tab 1 | `screens/home/home_page.dart` | Kerangka, data contoh |
| Donasi (daftar) | tab 2 | `screens/donasi/donasi_page.dart` | Kerangka |
| Riwayat | tab 3 | `screens/riwayat/riwayat_page.dart` | Placeholder |
| Profil | tab 4 | `screens/profil/profil_page.dart` | Kerangka + tombol Keluar |
| Donation Detail | `/kampanye/detail` | `screens/campaign/campaign_detail_page.dart` | Kerangka |
| Donation overlay, filled, payment | `/donasi/form` | `screens/campaign/donation_form_page.dart` | Placeholder |
| Donation Success | (belum) | (belum dibuat) | Belum |
| Notifikasi (ikon lonceng) | `/notifikasi` | `screens/notifikasi/notifications_page.dart` | Placeholder |
| Galang Dana | `/kampanye/ajukan` | `screens/campaign/submit_campaign_page.dart` | Placeholder |

Menu bawah: **Home, Donasi, Riwayat, Profil** (`screens/main_shell.dart`).

## 6. Bagian Figma yang sengaja tidak dipasang

| Di Figma | Alasan |
|---|---|
| Tombol "Sign in with MyITS" | Tidak ada di rencana fitur; login memakai email ITS lewat Supabase |
| "Forgot Password?" | Belum ada di rencana fitur (bisa ditambah nanti) |
| Pilihan "Rekening Virtual BCA" di aplikasi | Metode pembayaran dipilih di halaman Midtrans Snap |

## 7. Perlu disamakan di Figma

- Donasi minimum tertulis **Rp5.000** (overlay) dan **Rp15.000** (form). Laporan memakai **Rp5.000**.
- Label "Sembunyikan nama Anda" dan "Sembunyikan namamu": pilih satu gaya bahasa.
