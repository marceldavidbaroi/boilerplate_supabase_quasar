-- Update the trigger function to automatically promote davidubl007@gmail.com to superadmin
create or replace function public.handle_new_user()
returns trigger
security definer
set search_path = public
language plpgsql
as $$
begin
  insert into public.user_profiles (id, full_name, avatar_url, is_superadmin)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
    coalesce(new.raw_user_meta_data->>'avatar_url', null),
    (new.email = 'davidubl007@gmail.com')
  )
  on conflict (id) do update
  set is_superadmin = case 
    when new.email = 'davidubl007@gmail.com' then true 
    else public.user_profiles.is_superadmin 
  end;
  return new;
end;
$$;

-- Retroactively update if the user already exists in user_profiles
update public.user_profiles
set is_superadmin = true
where id in (select id from auth.users where email = 'davidubl007@gmail.com');
