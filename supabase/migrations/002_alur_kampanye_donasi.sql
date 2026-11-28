-- ITSbisa v2 | Alur kampanye (Proses A) dan donasi (Proses B)
-- Jalankan SETELAH itsbisa_supabase_v1.sql, sekali, di Dashboard > SQL Editor.
--
-- Isi file ini:
--   1. Kolom redirect_url untuk melanjutkan pembayaran tertunda (F08).
--   2. RPC get_campaigns: daftar, cari, filter kategori, detail kampanye (F03, F04).
--   3. RPC create_donation: membuat donasi + transaksi pending (F07).
--      Dipanggil oleh Edge Function create-donation, bukan langsung dari aplikasi.
--   4. RPC apply_payment_notification: memproses notifikasi Midtrans secara idempoten (F07).
--      Hanya service_role (Edge Function midtrans-notification).
--   5. close_campaigns: menutup kampanye saat tenggat habis (F10), dijadwalkan pg_cron.
--   6. Pencairan dana: request_disbursement (penggalang) dan process_disbursement (admin) (F11).
--   7. Laporan penggunaan dana: submit_fund_report (F12).
--   8. Bucket dan policy Storage untuk sampul, dokumen, bukti transfer, dan bukti laporan.

begin;

-- ---------------------------------------------------------------------------
-- 1. Kolom tambahan
-- ---------------------------------------------------------------------------
alter table public.payment_transactions add column redirect_url text;
grant select (redirect_url) on public.payment_transactions to authenticated;

-- Penggalang boleh menghapus draf miliknya sendiri (batal mengajukan).
grant delete on public.campaigns to authenticated;
create policy campaign_draft_delete on public.campaigns for delete to authenticated
using (owner_id = (select auth.uid()) and status = 'draft');

create index payment_transactions_status_idx on public.payment_transactions (status, expiry_time);

-- ---------------------------------------------------------------------------
-- 2. Daftar dan detail kampanye
--    Tabel profiles hanya bisa dibaca pemiliknya, jadi nama penggalang
--    diambil lewat fungsi ini (hanya full_name yang dibuka).
-- ---------------------------------------------------------------------------
create function public.get_campaigns(
    p_search text default null,
    p_category_id uuid default null,
    p_urgent_only boolean default false,
    p_campaign_id uuid default null,
    p_owner_only boolean default false,
    p_statuses text[] default null,
    p_limit integer default 20,
    p_offset integer default 0
)
returns table (
    id uuid,
    owner_id uuid,
    owner_name text,
    category_id uuid,
    category_name text,
    title text,
    story text,
    cover_image_url text,
    is_urgent boolean,
    target_amount numeric,
    collected_amount numeric,
    deadline timestamptz,
    status text,
    created_at timestamptz,
    donor_count bigint
)
language sql stable security definer set search_path = ''
as $$
    select c.id, c.owner_id, coalesce(nullif(btrim(p.full_name), ''), 'Penggalang ITS')::text,
           c.category_id, cat.name::text, c.title::text, c.story, c.cover_image_url,
           -- Mendesak: ditandai admin, atau kampanye aktif dengan tenggat <= 7 hari.
           (c.is_urgent or (c.status = 'active' and c.deadline <= now() + interval '7 days')),
           c.target_amount, c.collected_amount, c.deadline, c.status, c.created_at,
           (select count(*) from public.donations d where d.campaign_id = c.id and d.status = 'paid')
    from public.campaigns c
    join public.categories cat on cat.id = c.category_id
    left join public.profiles p on p.id = c.owner_id
    where auth.uid() is not null
      and (
          c.status in ('active', 'completed', 'disbursed', 'reported')
          or c.owner_id = auth.uid()
          or itsbisa_private.is_admin()
      )
      and (p_campaign_id is null or c.id = p_campaign_id)
      and (not coalesce(p_owner_only, false) or c.owner_id = auth.uid())
      and (p_statuses is null or c.status = any (p_statuses))
      and (p_category_id is null or c.category_id = p_category_id)
      and (
          not coalesce(p_urgent_only, false)
          or (c.status = 'active' and (c.is_urgent or c.deadline <= now() + interval '7 days'))
      )
      and (
          nullif(btrim(p_search), '') is null
          or strpos(lower(c.title), lower(btrim(p_search))) > 0
          or strpos(lower(cat.name), lower(btrim(p_search))) > 0
      )
    order by
        case when coalesce(p_owner_only, false) then 0 else (case when c.status = 'active' then 0 else 1 end) end,
        case when coalesce(p_owner_only, false) then c.created_at end desc,
        case when not coalesce(p_owner_only, false) then c.deadline end asc,
        c.id
    limit greatest(1, least(coalesce(p_limit, 20), 100))
    offset greatest(0, coalesce(p_offset, 0));
$$;

-- ---------------------------------------------------------------------------
-- 3. Membuat donasi (dipanggil Edge Function create-donation dengan JWT pengguna)
-- ---------------------------------------------------------------------------
create function public.create_donation(
    p_campaign_id uuid,
    p_amount numeric,
    p_is_anonymous boolean default false,
    p_message text default null
)
returns table (donation_id uuid, order_id text, gross_amount numeric)
language plpgsql security definer set search_path = ''
as $$
declare
    campaign public.campaigns%rowtype;
    new_donation_id uuid;
    new_order_id text;
begin
    if not itsbisa_private.is_verified_user() then
        raise exception 'Akun ITS aktif dan terverifikasi diperlukan';
    end if;
    if p_amount is null or p_amount < 5000 or p_amount <> trunc(p_amount) then
        raise exception 'Nominal donasi minimal Rp5.000 tanpa desimal';
    end if;
    if p_amount > 100000000 then
        raise exception 'Nominal donasi maksimal Rp100.000.000 per transaksi';
    end if;

    -- Kunci baris kampanye agar tidak bentrok dengan penutupan kampanye.
    select c.* into campaign from public.campaigns c where c.id = p_campaign_id for share;
    if not found or campaign.status <> 'active' then
        raise exception 'Kampanye tidak sedang menerima donasi';
    end if;
    if campaign.deadline <= now() then
        raise exception 'Tenggat kampanye sudah lewat';
    end if;

    insert into public.donations (campaign_id, donor_id, amount, is_anonymous, message)
    values (
        campaign.id, auth.uid(), p_amount, coalesce(p_is_anonymous, false),
        left(nullif(btrim(p_message), ''), 255)
    )
    returning id into new_donation_id;

    new_order_id := 'ITSB-' || new_donation_id::text;
    insert into public.payment_transactions (donation_id, order_id, gross_amount)
    values (new_donation_id, new_order_id, p_amount);

    return query select new_donation_id, new_order_id, p_amount;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Notifikasi Midtrans (dipanggil Edge Function midtrans-notification
--    setelah signature_key diperiksa). Idempoten berdasarkan order_id.
-- ---------------------------------------------------------------------------
create function public.apply_payment_notification(p_payload jsonb)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
    pay public.payment_transactions%rowtype;
    don public.donations%rowtype;
    camp public.campaigns%rowtype;
    tx_status text := p_payload ->> 'transaction_status';
    fraud text := coalesce(p_payload ->> 'fraud_status', 'accept');
    new_status text;
begin
    select * into pay from public.payment_transactions
    where order_id = p_payload ->> 'order_id' for update;
    if not found then
        return 'unknown_order';
    end if;
    if (p_payload ->> 'gross_amount')::numeric <> pay.gross_amount then
        raise exception 'Nominal notifikasi tidak cocok';
    end if;

    new_status := case
        when tx_status = 'capture' and fraud = 'accept' then 'settlement'
        when tx_status = 'capture' then 'deny'
        when tx_status in ('settlement', 'pending', 'expire', 'cancel', 'deny', 'failure', 'refund') then tx_status
        when tx_status = 'partial_refund' then 'refund'
        else null
    end;
    if new_status is null then
        return 'ignored';
    end if;

    -- Status final tidak diubah lagi, kecuali settlement -> refund.
    if pay.status = new_status
       or (pay.status in ('expire', 'cancel', 'deny', 'failure', 'refund'))
       or (pay.status = 'settlement' and new_status <> 'refund') then
        return 'no_change';
    end if;

    select * into don from public.donations where id = pay.donation_id for update;
    -- Kunci kampanye agar penambahan saldo tidak bentrok.
    select * into camp from public.campaigns where id = don.campaign_id for update;

    update public.payment_transactions
    set status = new_status,
        payment_type = coalesce(p_payload ->> 'payment_type', payment_type),
        -- Waktu dari Midtrans berformat lokal tanpa zona, jadi dipakai waktu server.
        settlement_time = case when new_status = 'settlement' then now() else settlement_time end,
        raw_payload = p_payload
    where id = pay.id;

    if new_status = 'settlement' then
        update public.donations set status = 'paid', paid_at = now() where id = don.id;
        -- Dana tetap dihitung walau kampanye sudah ditutup (rekonsiliasi pembayaran tertunda).
        update public.campaigns set collected_amount = collected_amount + don.amount
        where id = camp.id returning * into camp;

        insert into public.notifications (user_id, type, title, message, reference_id)
        values (don.donor_id, 'payment_success', 'Pembayaran berhasil',
                'Terima kasih! Donasi Anda untuk "' || camp.title || '" sudah diterima.', camp.id);
        insert into public.notifications (user_id, type, title, message, reference_id)
        values (camp.owner_id, 'donation_received', 'Donasi masuk',
                'Kampanye "' || camp.title || '" menerima donasi baru.', camp.id);

        if camp.status = 'active' and camp.collected_amount >= camp.target_amount then
            update public.campaigns set status = 'completed' where id = camp.id;
            insert into public.notifications (user_id, type, title, message, reference_id)
            values (camp.owner_id, 'campaign_completed', 'Target tercapai',
                    'Kampanye "' || camp.title || '" mencapai target dan ditutup. Ajukan pencairan dana.', camp.id);
        end if;

    elsif new_status = 'refund' then
        update public.donations set status = 'refunded' where id = don.id;
        update public.campaigns set collected_amount = greatest(0, collected_amount - don.amount)
        where id = camp.id;

    elsif new_status in ('expire', 'cancel', 'deny', 'failure') then
        update public.donations
        set status = case when new_status = 'expire' then 'expired' else 'failed' end
        where id = don.id and status = 'pending';
        insert into public.notifications (user_id, type, title, message, reference_id)
        values (don.donor_id, 'payment_failed', 'Pembayaran tidak berhasil',
                'Donasi untuk "' || camp.title || '" dibatalkan atau kedaluwarsa.', camp.id);
    end if;

    return new_status;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. Penutupan kampanye otomatis (tenggat habis)
-- ---------------------------------------------------------------------------
create function public.close_campaigns()
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
    closed integer;
begin
    with done as (
        update public.campaigns
        set status = 'completed'
        where status = 'active' and (deadline <= now() or collected_amount >= target_amount)
        returning id, owner_id, title
    ), notif as (
        insert into public.notifications (user_id, type, title, message, reference_id)
        select owner_id, 'campaign_completed', 'Kampanye selesai',
               'Kampanye "' || title || '" telah ditutup. Ajukan pencairan dana.', id
        from done
    )
    select count(*) into closed from done;

    -- Pembayaran pending yang sudah lewat batas waktunya dianggap kedaluwarsa.
    update public.donations d set status = 'expired'
    from public.payment_transactions p
    where p.donation_id = d.id and d.status = 'pending' and p.status = 'pending'
      and p.expiry_time is not null and p.expiry_time < now() - interval '15 minutes';
    update public.payment_transactions set status = 'expire'
    where status = 'pending' and expiry_time is not null
      and expiry_time < now() - interval '15 minutes';

    return closed;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Pencairan dana
-- ---------------------------------------------------------------------------
create function public.request_disbursement(p_campaign_id uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
    camp public.campaigns%rowtype;
    prof public.profiles%rowtype;
    existing public.disbursements%rowtype;
    result_id uuid;
begin
    if not itsbisa_private.is_verified_user() then
        raise exception 'Akun ITS aktif dan terverifikasi diperlukan';
    end if;

    select * into camp from public.campaigns
    where id = p_campaign_id and owner_id = auth.uid() for update;
    if not found then
        raise exception 'Kampanye tidak ditemukan';
    end if;
    if camp.status <> 'completed' then
        raise exception 'Pencairan hanya untuk kampanye yang sudah selesai';
    end if;
    if camp.collected_amount <= 0 then
        raise exception 'Belum ada dana terkumpul';
    end if;
    if exists (
        select 1 from public.donations d
        join public.payment_transactions p on p.donation_id = d.id
        where d.campaign_id = camp.id and d.status = 'pending'
          and (p.expiry_time is null or p.expiry_time > now())
    ) then
        raise exception 'Masih ada pembayaran tertunda. Coba lagi setelah pembayaran selesai atau kedaluwarsa';
    end if;

    select * into prof from public.profiles where id = auth.uid();
    if prof.payout_method is null or nullif(btrim(prof.bank_name), '') is null
       or nullif(btrim(prof.account_number), '') is null
       or nullif(btrim(prof.account_holder), '') is null then
        raise exception 'Lengkapi informasi rekening atau e-wallet di profil';
    end if;

    select * into existing from public.disbursements where campaign_id = camp.id for update;
    if found then
        if existing.status <> 'needs_revision' then
            raise exception 'Pencairan sudah diajukan';
        end if;
        update public.disbursements
        set amount = camp.collected_amount, payout_method = prof.payout_method,
            bank_name = prof.bank_name, account_number = prof.account_number,
            account_holder = prof.account_holder, status = 'requested',
            admin_note = null, processed_at = null, requested_at = now()
        where id = existing.id
        returning id into result_id;
    else
        insert into public.disbursements (campaign_id, amount, payout_method, bank_name, account_number, account_holder)
        values (camp.id, camp.collected_amount, prof.payout_method, prof.bank_name, prof.account_number, prof.account_holder)
        returning id into result_id;
    end if;
    return result_id;
end;
$$;

create function public.process_disbursement(
    p_disbursement_id uuid,
    p_approve boolean,
    p_admin_note text default null,
    p_transfer_proof_url text default null
)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
    disb public.disbursements%rowtype;
    camp public.campaigns%rowtype;
begin
    if not itsbisa_private.is_admin() then
        raise exception 'Akses admin diperlukan';
    end if;

    select * into disb from public.disbursements where id = p_disbursement_id for update;
    if not found or disb.status <> 'requested' then
        raise exception 'Pengajuan pencairan tidak sedang menunggu diproses';
    end if;
    select * into camp from public.campaigns where id = disb.campaign_id for update;

    if p_approve then
        if nullif(btrim(p_transfer_proof_url), '') is null then
            raise exception 'Unggah bukti transfer terlebih dahulu';
        end if;
        update public.disbursements
        set status = 'paid', processed_at = now(), transfer_proof_url = p_transfer_proof_url,
            admin_note = nullif(btrim(p_admin_note), '')
        where id = disb.id;
        update public.campaigns set status = 'disbursed' where id = camp.id;
        insert into public.notifications (user_id, type, title, message, reference_id)
        values (camp.owner_id, 'disbursement_paid', 'Dana dicairkan',
                'Dana kampanye "' || camp.title || '" sudah ditransfer. Unggah laporan penggunaan dana.', camp.id);
    else
        if nullif(btrim(p_admin_note), '') is null then
            raise exception 'Tuliskan alasan perbaikan';
        end if;
        update public.disbursements
        set status = 'needs_revision', processed_at = now(), admin_note = btrim(p_admin_note)
        where id = disb.id;
        insert into public.notifications (user_id, type, title, message, reference_id)
        values (camp.owner_id, 'disbursement_revision', 'Pencairan perlu diperbaiki',
                btrim(p_admin_note), camp.id);
    end if;
    return disb.id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. Laporan penggunaan dana
-- ---------------------------------------------------------------------------
create function public.submit_fund_report(
    p_campaign_id uuid,
    p_description text,
    p_total_used numeric,
    p_evidence_paths text[]
)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
    camp public.campaigns%rowtype;
    new_report_id uuid;
    evidence_path text;
begin
    if not itsbisa_private.is_verified_user() then
        raise exception 'Akun ITS aktif dan terverifikasi diperlukan';
    end if;
    select * into camp from public.campaigns
    where id = p_campaign_id and owner_id = auth.uid() for update;
    if not found or camp.status <> 'disbursed' then
        raise exception 'Laporan hanya dapat dibuat setelah dana dicairkan';
    end if;
    if nullif(btrim(p_description), '') is null or p_total_used is null or p_total_used <= 0 then
        raise exception 'Isi keterangan dan total dana yang digunakan';
    end if;
    if p_evidence_paths is null or cardinality(p_evidence_paths) = 0 then
        raise exception 'Tambahkan minimal satu bukti';
    end if;

    insert into public.fund_usage_reports (campaign_id, description, total_used)
    values (camp.id, btrim(p_description), p_total_used)
    returning id into new_report_id;

    foreach evidence_path in array p_evidence_paths loop
        if nullif(btrim(evidence_path), '') is not null then
            insert into public.report_evidence (report_id, file_path)
            values (new_report_id, btrim(evidence_path))
            on conflict do nothing;
        end if;
    end loop;

    update public.campaigns set status = 'reported' where id = camp.id;

    -- Beri tahu donatur bahwa laporan sudah terbit.
    insert into public.notifications (user_id, type, title, message, reference_id)
    select distinct d.donor_id, 'report_published', 'Laporan penggunaan dana',
           'Laporan kampanye "' || camp.title || '" sudah dipublikasikan.', camp.id
    from public.donations d
    where d.campaign_id = camp.id and d.status = 'paid';

    return new_report_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Hak akses fungsi
-- ---------------------------------------------------------------------------
revoke all on function
    public.get_campaigns(text, uuid, boolean, uuid, boolean, text[], integer, integer),
    public.create_donation(uuid, numeric, boolean, text),
    public.apply_payment_notification(jsonb),
    public.close_campaigns(),
    public.request_disbursement(uuid),
    public.process_disbursement(uuid, boolean, text, text),
    public.submit_fund_report(uuid, text, numeric, text[])
from public, anon, authenticated;

grant execute on function
    public.get_campaigns(text, uuid, boolean, uuid, boolean, text[], integer, integer),
    public.create_donation(uuid, numeric, boolean, text),
    public.request_disbursement(uuid),
    public.process_disbursement(uuid, boolean, text, text),
    public.submit_fund_report(uuid, text, numeric, text[])
to authenticated;

grant execute on function public.apply_payment_notification(jsonb), public.close_campaigns()
to service_role;

-- ---------------------------------------------------------------------------
-- 8. Storage
--    campaign-covers   : publik, foto sampul kampanye        path: <uid>/<nama-file>
--    campaign-documents: privat, dokumen pendukung           path: <uid>/<campaign_id>/<nama-file>
--    report-evidence   : publik, bukti laporan dana          path: <uid>/<campaign_id>/<nama-file>
--    transfer-proofs   : privat, bukti transfer dari admin   path: <campaign_id>/<nama-file>
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
    ('campaign-covers', 'campaign-covers', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
    ('campaign-documents', 'campaign-documents', false, 10485760, array['image/jpeg', 'image/png', 'application/pdf']),
    ('report-evidence', 'report-evidence', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
    ('transfer-proofs', 'transfer-proofs', false, 5242880, array['image/jpeg', 'image/png', 'application/pdf'])
on conflict (id) do nothing;

-- Pengguna hanya mengunggah ke folder dengan nama uid miliknya.
create policy itsbisa_own_upload on storage.objects for insert to authenticated
with check (
    bucket_id in ('campaign-covers', 'campaign-documents', 'report-evidence')
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select itsbisa_private.is_verified_user())
);
create policy itsbisa_own_delete on storage.objects for delete to authenticated
using (
    bucket_id in ('campaign-covers', 'campaign-documents', 'report-evidence')
    and (storage.foldername(name))[1] = (select auth.uid())::text
);
-- Dokumen pendukung: pemilik dan admin dapat membaca (lewat signed URL).
create policy itsbisa_documents_read on storage.objects for select to authenticated
using (
    bucket_id = 'campaign-documents'
    and ((storage.foldername(name))[1] = (select auth.uid())::text or (select itsbisa_private.is_admin()))
);
-- Bukti transfer: admin mengunggah, admin dan pemilik kampanye membaca.
create policy itsbisa_proof_admin_write on storage.objects for insert to authenticated
with check (bucket_id = 'transfer-proofs' and (select itsbisa_private.is_admin()));
create policy itsbisa_proof_read on storage.objects for select to authenticated
using (
    bucket_id = 'transfer-proofs' and (
        (select itsbisa_private.is_admin()) or exists (
            select 1 from public.campaigns c
            where c.id::text = (storage.foldername(name))[1] and c.owner_id = (select auth.uid())
        )
    )
);

commit;

-- ---------------------------------------------------------------------------
-- 9. Penjadwalan (jalankan TERPISAH setelah blok di atas berhasil)
--    Aktifkan dulu extension pg_cron di Dashboard > Database > Extensions.
-- ---------------------------------------------------------------------------
-- select cron.schedule('itsbisa-close-campaigns', '*/15 * * * *', $$select public.close_campaigns()$$);
