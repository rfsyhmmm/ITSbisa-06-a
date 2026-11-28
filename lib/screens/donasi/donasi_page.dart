import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/campaign_card.dart';
import 'package:itsbisa/widgets/its_ui.dart';

/// Tab Donasi = Figma S02.02 "Temukan Kampanye" dan S02.03 "Hasil Pencarian" (F03).
class DonasiPage extends StatefulWidget {
  const DonasiPage({super.key, this.initialQuery = ''});

  /// Kata kunci dari kolom pencarian di Home.
  final String initialQuery;

  @override
  State<DonasiPage> createState() => _DonasiPageState();
}

class _DonasiPageState extends State<DonasiPage> {
  late final _search = TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery.trim();
  List<CampaignCategory> _categories = const [];
  String? _categoryId;
  late Future<List<Campaign>> _future = _load();

  @override
  void initState() {
    super.initState();
    CampaignService.fetchCategories()
        .then((c) {
          if (mounted) setState(() => _categories = c);
        })
        .catchError((_) {});
  }

  @override
  void didUpdateWidget(covariant DonasiPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      _search.text = widget.initialQuery;
      _submitSearch();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Campaign>> _load() => CampaignService.fetchCampaigns(
    search: _query,
    categoryId: _categoryId,
    limit: 50,
  );

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  void _submitSearch() {
    _query = _search.text.trim();
    _reload();
  }

  void _clearSearch() {
    _search.clear();
    _submitSearch();
  }

  Future<void> _open(Campaign c, {bool donate = false}) async {
    await Navigator.pushNamed(
      context,
      donate ? AppRoutes.donationForm : AppRoutes.campaignDetail,
      arguments: c,
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;
    return ItsPage(
      title: searching ? 'Hasil Pencarian' : 'Temukan Kampanye',
      onRefresh: _reload,
      children: [
        TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submitSearch(),
          decoration: InputDecoration(
            hintText: 'Cari kampanye atau kebutuhan',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searching
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
        _CategoryChips(
          categories: _categories,
          selectedId: _categoryId,
          onSelected: (id) {
            setState(() => _categoryId = id);
            _reload();
          },
        ),
        if (searching)
          ItsHeadline(
            'Hasil untuk “$_query”',
            subtitle: 'Kampanye yang sesuai dengan pencarian Anda.',
          )
        else
          const Text(
            'Kampanye aktif',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        FutureBuilder<List<Campaign>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError)
              return ErrorRetry(error: snap.error!, onRetry: _reload);
            final items = snap.data!;
            return Column(
              children: [
                if (items.isNotEmpty)
                  _CampaignGrid(campaigns: items, onOpen: _open),
                if (searching || items.isEmpty) ...[
                  const SizedBox(height: 16),
                  InfoCard(
                    title: 'Belum menemukan yang sesuai?',
                    titleSize: 16,
                    children: [
                      const CardText(
                        'Gunakan kata kunci lain atau jelajahi kategori bantuan.',
                      ),
                      CardButton(
                        label: 'Jelajahi Kampanye',
                        onPressed: _clearSearch,
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Kartu kampanye dua kolom, sama seperti kartu di Home.
class _CampaignGrid extends StatelessWidget {
  const _CampaignGrid({required this.campaigns, required this.onOpen});

  final List<Campaign> campaigns;
  final void Function(Campaign c, {bool donate}) onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in campaigns)
              CampaignCard(
                campaign: c,
                width: width,
                onTap: () => onOpen(c),
                onDonate: c.acceptsDonation
                    ? () => onOpen(c, donate: true)
                    : null,
              ),
          ],
        );
      },
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CampaignCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String? id) {
      final selected = selectedId == id;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSelected(id),
          showCheckmark: false,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori bantuan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip('Semua', null),
              for (final c in categories) chip(c.name, c.id),
            ],
          ),
        ),
      ],
    );
  }
}
