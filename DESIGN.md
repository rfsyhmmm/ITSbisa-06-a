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
| `AppColors.primary` | `#0CC0D9` (BiruMuda/B300) | Tombol utama, menu bawah aktif, progress bar, gelombang |
| `AppColors.primaryLight` | `#E7F9FB` | Latar Login/Register/Splash, latar ikon |
| `AppColors.navy` | `#0B2A5B` | Logo, tombol **Donasi** di detail kampanye, ikon header |
| `AppColors.background` | `#F7FBFC` | Latar halaman umum |
| `AppColors.surface` | `#FFFFFF` | Kartu, kolom input, AppBar |
| `AppColors.textPrimary` | `#1F2933` | Teks utama |
| `AppColors.textSecondary` | `#8A94A6` | Teks keterangan, hint, menu bawah tidak aktif |
| `AppColors.border` | `#DDE3EA` | Garis kolom input, latar progress bar |
| `AppColors.verified` | `#2F80ED` | Ikon centang akun terverifikasi |
| `AppColors.success` / `successLight` | `#1E9E5A` / `#E3F6EC` | Status Berhasil, Selesai, Dicairkan |
| `AppColors.warning` / `warningLight` | `#D98A00` / `#FFF3DC` | Menunggu pembayaran, Menunggu verifikasi |
| `AppColors.danger` / `dangerLight` | `#D64545` / `#FDE8E8` | Gagal, Ditolak, Perlu perbaikan |

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
| Foto sampul kampanye | `campaign_cover.dart` | `CampaignCover(url: c.coverImageUrl, height: 200)` |
| Label status | `status_chip.dart` | `StatusChip(label: c.statusLabel, tone: campaignTone(c.status))` |
| Error / kosong | `async_states.dart` | `ErrorRetry(...)`, `EmptyState(...)`, `showSnack(context, '...')` |
| Rekening pencairan | `payout_sheet.dart` | `PayoutCard(info: ..., onEdit: ...)`, `PayoutSheet.show(context, info)` |

## 5. Daftar halaman

Halaman alur kampanye & donasi mengikuti frame **Canonical UI** di halaman Figma
`ITSBisa_sandbox_codex w13` (kode frame di kolom pertama).

| Figma | Rute | File |
|---|---|---|
| Splash | `/` | `screens/splash/splash_page.dart` |
| Login / Register | `/masuk` (belum login) | `screens/auth/auth_page.dart` |
| Home | tab 1 | `screens/home/home_page.dart` |
| S02.02 Temukan Kampanye, S02.03 Hasil Pencarian | tab 2 | `screens/donasi/donasi_page.dart` |
| S05.06 Riwayat | tab 3 | `screens/riwayat/riwayat_page.dart` |
| Profil (+ Panel Admin) | tab 4 | `screens/profil/profil_page.dart` |
| Detail kampanye | `/kampanye/detail` | `screens/campaign/campaign_detail_page.dart` |
| S05.01 Donasi Dana + sheet 101:6006 | `/donasi/form` | `screens/campaign/donation_form_page.dart`, `widgets/amount_sheet.dart` |
| S05.04 Pembayaran Donasi | `/donasi/status` | `screens/campaign/payment_status_page.dart` |
| 101:5873 Terima kasih | `/donasi/berhasil` | `screens/campaign/donation_success_page.dart` |
| S05.07 Detail Donasi Dana | `/donasi/detail` | `screens/riwayat/donation_detail_page.dart` |
| S03.01 Ajukan Kampanye (jenis) | `/kampanye/baru` | `screens/campaign/create_campaign_type_page.dart` |
| S03.02 Informasi Kampanye | `/kampanye/ajukan` | `screens/campaign/submit_campaign_page.dart` |
| S03.06 Tinjau Pengajuan | `/kampanye/ajukan/tinjau` | `screens/campaign/submit_review_page.dart` |
| S03.08 Kampanye Saya | `/kampanye/saya` | `screens/campaign/my_campaigns_page.dart` |
| S03.09 Kelola Kampanye, S07.04 Kampanye Selesai | `/kampanye/kelola` | `screens/campaign/manage_campaign_page.dart` |
| S08.01 Ajukan Pencairan, S08.02 Status Pencairan | `/kampanye/pencairan` | `screens/campaign/disbursement_page.dart` |
| S08.06 Laporan Penggunaan Dana | `/kampanye/laporan` | `screens/campaign/fund_report_page.dart` |
| S08.07 Laporan Bantuan Dana | `/kampanye/laporan/tinjau` | `screens/campaign/fund_report_preview_page.dart` |
| S04.01 Dashboard Admin | `/admin` | `screens/admin/admin_page.dart` |
| S04.02 Verifikasi Kampanye | `/admin/kampanye` | `screens/admin/admin_page.dart` |
| S04.03 Tinjau Kampanye (+ S04.04 dokumen) | `/admin/kampanye/tinjau` | `screens/admin/admin_review_page.dart` |
| S04.05 Keputusan Pemeriksaan | `/admin/kampanye/keputusan` | `screens/admin/admin_decision_page.dart` |
| S08.03 Antrean Pencairan | `/admin/pencairan` | `screens/admin/admin_page.dart` |
| S08.04 Pemeriksaan Pencairan | `/admin/pencairan/periksa` | `screens/admin/admin_disbursement_review_page.dart` |
| Notifikasi | `/notifikasi` | `screens/notifikasi/notifications_page.dart` (placeholder) |

Belum dibuat (di luar cakupan alur kampanye & donasi dana): S02.05/S03.04/S06/S09 (Barang),
S07.01–S07.02 (kelola kabar terbaru), S10 (notifikasi & lencana), S11 (kelola admin).

### Komponen Canonical UI (`widgets/its_ui.dart`)

| Komponen | Pemakaian |
|---|---|
| `ItsPage` | Kerangka halaman: judul navy rata kiri, latar `primaryLight`, tombol utama di area putih bawah (`bottom:`) |
| `ItsHeadline` | Judul besar navy 24 + subjudul abu-abu |
| `InfoCard` | Kartu putih sudut 16; `overline` label kecil biru kapital, `title` 18 SemiBold |
| `CardText` | Teks isi 14; `muted: true` untuk keterangan 12 abu-abu |
| `AmountText` | Nominal besar navy (Rp50.000) |
| `CardButton` | Tombol biru penuh di dalam kartu (tinggi 44); merah: `color: AppColors.danger` |
| `UploadTile` | Kotak biru muda "+ Unggah dokumen" + daftar berkas terpilih |
| `FieldLabel` | Label di atas kolom input |

Font Figma: **Manrope** (judul) dan **Inter** (isi). Belum dipasang di proyek; tambahkan lewat `assets/fonts` bila ingin sama persis.

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
