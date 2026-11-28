import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/screens/campaign/submit_review_page.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/services/file_pick_service.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/payout_sheet.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Figma S03.02 "Informasi Kampanye" (F05): informasi utama, penerima, dokumen.
/// "Tinjau Pengajuan" membuka S03.06; pengajuan dikirim dari halaman tinjau.
class SubmitCampaignPage extends StatefulWidget {
  const SubmitCampaignPage({super.key});

  @override
  State<SubmitCampaignPage> createState() => _SubmitCampaignPageState();
}

class _SubmitCampaignPageState extends State<SubmitCampaignPage> {
  static const _recipientTypes = [
    'Mahasiswa',
    'Keluarga mahasiswa',
    'Tenaga kependidikan',
    'Organisasi',
    'Lainnya',
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _story = TextEditingController();
  final _target = TextEditingController();
  final _recipientName = TextEditingController();
  final _identity = TextEditingController();
  final _phone = TextEditingController();

  List<CampaignCategory> _categories = const [];
  PayoutInfo? _payout;
  String? _categoryId;
  DateTime? _deadline;
  bool _isSelf = true;
  String _recipientType = _recipientTypes.first;
  PickedFile? _cover;
  PickedFile? _consent;
  final List<PickedFile> _documents = [];
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _story,
      _target,
      _recipientName,
      _identity,
      _phone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait<Object>([
        CampaignService.fetchCategories(),
        CampaignService.fetchMyProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<CampaignCategory>;
        _payout = results[1] as PayoutInfo;
        if (_isSelf && _recipientName.text.isEmpty)
          _recipientName.text = _payout?.fullName ?? '';
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editPayout() async {
    if (!await PayoutSheet.show(context, _payout)) return;
    final info = await CampaignService.fetchMyProfile();
    if (mounted) setState(() => _payout = info);
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 180)),
      helpText: 'Tenggat kampanye',
    );
    if (picked != null)
      setState(
        () =>
            _deadline = DateTime(picked.year, picked.month, picked.day, 23, 59),
      );
  }

  Future<void> _pick(
    Future<PickedFile?> Function() picker,
    void Function(PickedFile) onPicked,
  ) async {
    try {
      final file = await picker();
      if (file != null && mounted) setState(() => onPicked(file));
    } catch (e) {
      if (mounted)
        showSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  void _review() {
    if (!_formKey.currentState!.validate()) return;
    String? problem;
    if (_deadline == null) {
      problem = 'Pilih tenggat kampanye';
    } else if (_documents.isEmpty) {
      problem = 'Unggah minimal satu dokumen pendukung';
    } else if (!_isSelf && _consent == null) {
      problem = 'Unggah surat persetujuan penerima';
    } else if (!(_payout?.isComplete ?? false)) {
      problem = 'Lengkapi rekening pencairan terlebih dahulu';
    }
    if (problem != null) {
      showSnack(context, problem);
      return;
    }

    final draft = CampaignDraft(
      categoryId: _categoryId!,
      title: _title.text,
      story: _story.text,
      targetAmount: parseRupiah(_target.text),
      deadline: _deadline!,
      isSelf: _isSelf,
      recipientType: _isSelf ? 'Diri sendiri' : _recipientType,
      recipientName: _recipientName.text,
      identityNumber: _identity.text,
      contactPhone: _phone.text,
      cover: _cover,
      documents: [for (final d in _documents) (type: 'pendukung', file: d)],
      consent: _isSelf ? null : _consent,
    );
    Navigator.pushNamed(
      context,
      AppRoutes.submitReview,
      arguments: SubmitReviewArgs(
        draft: draft,
        categoryName: _categories.firstWhere((c) => c.id == _categoryId).name,
        organizer: _payout?.fullName ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _loadError != null) {
      return ItsPage(
        title: 'Informasi Kampanye',
        children: [
          if (_loadError != null)
            ErrorRetry(error: _loadError!, onRetry: _load)
          else
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: ItsPage(
        title: 'Informasi Kampanye',
        bottom: PrimaryButton(label: 'Tinjau Pengajuan', onPressed: _review),
        children: [
          const ItsHeadline('Ceritakan kebutuhan Anda'),
          InfoCard(
            title: 'Informasi utama',
            children: [
              const FieldLabel('Judul kampanye'),
              TextFormField(
                controller: _title,
                maxLength: 150,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Dukungan UKT mahasiswa ITS',
                  counterText: '',
                ),
                validator: _required,
              ),
              const FieldLabel('Kategori'),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                hint: const Text('Pilih kategori bantuan'),
                items: [
                  for (final c in _categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 12),
              _CoverTile(
                file: _cover,
                onPick: () =>
                    _pick(FilePickService.pickImage, (f) => _cover = f),
                onRemove: () => setState(() => _cover = null),
              ),
              const FieldLabel('Target dana'),
              TextFormField(
                controller: _target,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                ),
                validator: (v) => parseRupiah(v ?? '') < 50000
                    ? 'Target minimal Rp50.000'
                    : null,
              ),
              const FieldLabel('Tenggat kampanye'),
              InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.event),
                  ),
                  child: Text(
                    _deadline == null
                        ? 'Pilih tanggal berakhir'
                        : formatDate(_deadline),
                    style: TextStyle(
                      color: _deadline == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const FieldLabel('Cerita kampanye'),
              TextFormField(
                controller: _story,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan latar belakang, kebutuhan, dan rencana penggunaan bantuan.',
                ),
                validator: (v) => (v == null || v.trim().length < 30)
                    ? 'Minimal 30 karakter'
                    : null,
              ),
            ],
          ),
          InfoCard(
            title: 'Penerima bantuan',
            children: [
              const FieldLabel('Pengajuan untuk'),
              DropdownButtonFormField<bool>(
                initialValue: _isSelf,
                items: const [
                  DropdownMenuItem(value: true, child: Text('Diri sendiri')),
                  DropdownMenuItem(value: false, child: Text('Orang lain')),
                ],
                onChanged: (v) => setState(() {
                  _isSelf = v ?? true;
                  _recipientName.text = _isSelf
                      ? (_payout?.fullName ?? '')
                      : '';
                }),
              ),
              if (!_isSelf) ...[
                const FieldLabel('Hubungan / jenis penerima'),
                DropdownButtonFormField<String>(
                  initialValue: _recipientType,
                  items: [
                    for (final t in _recipientTypes)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setState(
                    () => _recipientType = v ?? _recipientTypes.first,
                  ),
                ),
              ],
              const FieldLabel('Nama penerima'),
              TextFormField(
                controller: _recipientName,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama penerima',
                ),
                validator: _required,
              ),
              const FieldLabel('Identitas penerima'),
              TextFormField(
                controller: _identity,
                decoration: const InputDecoration(
                  hintText: 'NRP / NIP atau identitas terkait',
                ),
              ),
              const FieldLabel('No. HP penerima (opsional)'),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              const CardText(
                'Jika mewakili orang lain, sertakan surat persetujuan penerima.',
                muted: true,
              ),
            ],
          ),
          InfoCard(
            title: 'Dokumen pendukung',
            children: [
              UploadTile(
                title: 'Unggah dokumen',
                caption: 'Lampirkan dokumen yang mendukung kebutuhan kampanye (JPG, PNG, PDF).',
                onTap: () =>
                    _pick(FilePickService.pickDocument, _documents.add),
                files: [
                  for (var i = 0; i < _documents.length; i++)
                    (
                      name: _documents[i].name,
                      onRemove: () => setState(() => _documents.removeAt(i)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              UploadTile(
                title: 'Surat persetujuan',
                caption: 'Wajib untuk pengajuan atas nama orang lain.',
                onTap: () =>
                    _pick(FilePickService.pickDocument, (f) => _consent = f),
                files: [
                  if (_consent != null)
                    (
                      name: _consent!.name,
                      onRemove: () => setState(() => _consent = null),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const CardText(
                'Dokumen hanya digunakan untuk pemeriksaan admin dan tidak ditampilkan kepada publik.',
                muted: true,
              ),
            ],
          ),
          InfoCard(
            title: 'Rekening pencairan',
            children: [
              PayoutCard(info: _payout, onEdit: _editPayout),
              const SizedBox(height: 8),
              const CardText(
                'Rekening bersifat privat dan dipakai saat pencairan dana.',
                muted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kotak "+ Foto sampul" (berubah menjadi pratinjau setelah dipilih).
class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  final PickedFile? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return UploadTile(
        title: 'Foto sampul',
        caption: 'Gunakan foto yang menggambarkan kebutuhan penerima.',
        onTap: onPick,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.memory(
            file!.bytes,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton.filled(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
