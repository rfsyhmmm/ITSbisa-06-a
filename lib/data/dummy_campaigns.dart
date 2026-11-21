import 'package:itsbisa/models/campaign.dart';

/// Data contoh untuk tampilan. Diganti data Supabase oleh tim backend.
const dummyCampaigns = <Campaign>[
  Campaign(
    id: '1',
    title: 'Penggalangan Dana Uang Duka Mahasiswa ITS 2026',
    organizer: 'ITS 2026',
    category: 'Bencana/Musibah',
    targetAmount: 2000000,
    collectedAmount: 200000,
    daysLeft: 7,
    isVerified: true,
    isUrgent: true,
  ),
  Campaign(
    id: '2',
    title: 'Bantu UKT Semester Genap Mahasiswa Rantau',
    organizer: 'HMSI ITS',
    category: 'UKT',
    targetAmount: 5000000,
    collectedAmount: 3250000,
    daysLeft: 12,
    isVerified: true,
    isUrgent: true,
  ),
  Campaign(
    id: '3',
    title: 'Biaya Pengobatan Teman Kita di RS',
    organizer: 'Angkatan 2024',
    category: 'Kesehatan',
    targetAmount: 10000000,
    collectedAmount: 1000,
    daysLeft: 20,
  ),
];
