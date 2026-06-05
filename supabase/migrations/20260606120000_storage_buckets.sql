-- Halo Storage buckets and RLS policies for avatars and post media.
-- Buckets stay private: clients upload paths, then request signed URLs.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'halo-avatars',
    'halo-avatars',
    false,
    5242880,
    array['image/jpeg', 'image/jpg', 'image/png', 'image/heic', 'image/webp']
  ),
  (
    'halo-media',
    'halo-media',
    false,
    52428800,
    array[
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/heic',
      'image/webp',
      'audio/m4a',
      'audio/mp4',
      'audio/aac',
      'audio/wav'
    ]
  )
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists storage_avatars_select_authenticated on storage.objects;
create policy storage_avatars_select_authenticated on storage.objects
  for select to authenticated
  using (bucket_id = 'halo-avatars');

drop policy if exists storage_avatars_insert_own_folder on storage.objects;
create policy storage_avatars_insert_own_folder on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'halo-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists storage_avatars_update_own_folder on storage.objects;
create policy storage_avatars_update_own_folder on storage.objects
  for update to authenticated
  using (
    bucket_id = 'halo-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'halo-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists storage_avatars_delete_own_folder on storage.objects;
create policy storage_avatars_delete_own_folder on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'halo-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists storage_media_select_visible_post on storage.objects;
create policy storage_media_select_visible_post on storage.objects
  for select to authenticated
  using (
    bucket_id = 'halo-media'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or exists (
        select 1
        from public.halo_posts p
        where p.media_path = storage.objects.name
          and p.expires_at > now()
          and (
            p.user_id = auth.uid()
            or public.tier_rank(public.viewer_tier_towards(p.user_id))
               >= public.tier_rank(p.min_tier)
            or (
              p.min_tier = 'nebula'
              and exists (
                select 1
                from public.profiles author
                where author.id = p.user_id
                  and author.is_public = true
              )
            )
          )
      )
    )
  );

drop policy if exists storage_media_insert_own_folder on storage.objects;
create policy storage_media_insert_own_folder on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'halo-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists storage_media_update_own_folder on storage.objects;
create policy storage_media_update_own_folder on storage.objects
  for update to authenticated
  using (
    bucket_id = 'halo-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'halo-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists storage_media_delete_own_folder on storage.objects;
create policy storage_media_delete_own_folder on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'halo-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
