-- 1. Create base tables

-- Create tenants table
create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  parent_id uuid references public.tenants(id) on delete set null,
  status text not null default 'active',
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Create tenant_settings table
create table public.tenant_settings (
  tenant_id uuid primary key references public.tenants(id) on delete cascade,
  logo_url text,
  theme_color text,
  enabled_features jsonb not null default '{}'::jsonb,
  preferences jsonb not null default '{}'::jsonb,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Create tenant_roles table
create table public.tenant_roles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade,
  name text not null,
  description text,
  permissions jsonb not null default '{}'::jsonb,
  is_system_role boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  unique (tenant_id, name)
);

-- Create user_profiles table
create table public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  avatar_url text,
  is_superadmin boolean not null default false,
  preferences jsonb not null default '{"ui": {"theme": "dark", "sidebar_collapsed": false}, "notifications": {"email": true, "push": false}}'::jsonb,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Create tenant_members table
create table public.tenant_members (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role_id uuid not null references public.tenant_roles(id) on delete restrict,
  status text not null default 'active',
  joined_at timestamp with time zone not null default now(),
  unique (tenant_id, user_id)
);

-- Create tenant_invitations table
create table public.tenant_invitations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  email text not null,
  role_id uuid not null references public.tenant_roles(id) on delete cascade,
  token text not null unique,
  invited_by uuid not null references auth.users(id) on delete cascade,
  expires_at timestamp with time zone not null,
  status text not null default 'pending',
  created_at timestamp with time zone not null default now()
);

-- Create tenant_billing table
create table public.tenant_billing (
  tenant_id uuid primary key references public.tenants(id) on delete cascade,
  stripe_customer_id text,
  stripe_subscription_id text,
  subscription_tier text not null default 'free',
  status text not null default 'active',
  current_period_end timestamp with time zone,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- 2. Add indexes
create index idx_tenants_parent_id on public.tenants(parent_id);
create index idx_tenant_roles_tenant_id on public.tenant_roles(tenant_id);
create index idx_tenant_members_tenant_id on public.tenant_members(tenant_id);
create index idx_tenant_members_user_id on public.tenant_members(user_id);
create index idx_tenant_invitations_tenant_id on public.tenant_invitations(tenant_id);
create index idx_tenant_invitations_token on public.tenant_invitations(token);

-- 3. Seed default system roles
insert into public.tenant_roles (id, tenant_id, name, description, permissions, is_system_role)
values
  (
    '00000000-0000-0000-0000-000000000001',
    null,
    'Owner',
    'Full organization control.',
    '{"all": true}'::jsonb,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    null,
    'Admin',
    'Administrator control.',
    '{"modules": {"settings": {"write": true, "read": true}, "members": {"write": true, "read": true}}}'::jsonb,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    null,
    'Member',
    'Standard access.',
    '{"modules": {"settings": {"write": false, "read": true}, "members": {"write": false, "read": true}}}'::jsonb,
    true
  );

-- 4. Create common updated_at trigger helper
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_tenants_updated_at before update on public.tenants for each row execute procedure public.set_updated_at();
create trigger set_tenant_settings_updated_at before update on public.tenant_settings for each row execute procedure public.set_updated_at();
create trigger set_tenant_roles_updated_at before update on public.tenant_roles for each row execute procedure public.set_updated_at();
create trigger set_user_profiles_updated_at before update on public.user_profiles for each row execute procedure public.set_updated_at();
create trigger set_tenant_billing_updated_at before update on public.tenant_billing for each row execute procedure public.set_updated_at();

-- 5. Create core security helper functions

create or replace function public.is_superadmin()
returns boolean
security definer
stable
set search_path = public
language plpgsql
as $$
begin
  return exists (
    select 1 from public.user_profiles
    where id = auth.uid() and is_superadmin = true
  );
end;
$$;

create or replace function public.is_tenant_member(p_tenant_id uuid)
returns boolean
security definer
stable
set search_path = public
language plpgsql
as $$
begin
  if exists (
    select 1 from public.user_profiles
    where id = auth.uid() and is_superadmin = true
  ) then
    return true;
  end if;

  return exists (
    select 1 from public.tenant_members
    where tenant_id = p_tenant_id and user_id = auth.uid() and status = 'active'
  );
end;
$$;

create or replace function public.is_tenant_owner(p_tenant_id uuid)
returns boolean
security definer
stable
set search_path = public
language plpgsql
as $$
begin
  if exists (
    select 1 from public.user_profiles
    where id = auth.uid() and is_superadmin = true
  ) then
    return true;
  end if;

  return exists (
    select 1 from public.tenant_members m
    join public.tenant_roles r on m.role_id = r.id
    where m.tenant_id = p_tenant_id 
      and m.user_id = auth.uid() 
      and m.status = 'active'
      and r.name = 'Owner'
  );
end;
$$;

create or replace function public.get_selected_tenant_id()
returns uuid
stable
security definer
set search_path = public
language plpgsql
as $$
declare
  v_tenant_id text;
begin
  v_tenant_id := current_setting('request.headers', true)::json->>'x-selected-tenant-id';
  if v_tenant_id is not null then
    return v_tenant_id::uuid;
  end if;
  return null;
exception
  when others then
    return null;
end;
$$;

-- 6. Create automation triggers

-- Trigger for creating public profile automatically upon signup
create or replace function public.handle_new_user()
returns trigger
security definer
set search_path = public
language plpgsql
as $$
begin
  insert into public.user_profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
    coalesce(new.raw_user_meta_data->>'avatar_url', null)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Trigger for protecting enabled features (only editable by superadmins)
create or replace function public.protect_enabled_features()
returns trigger
security definer
set search_path = public
language plpgsql
as $$
begin
  if old.enabled_features is distinct from new.enabled_features then
    if not public.is_superadmin() then
      raise exception 'Only platform superadmins can change enabled features.';
    end if;
  end if;
  return new;
end;
$$;

create trigger protect_tenant_settings_features
  before update on public.tenant_settings
  for each row execute procedure public.protect_enabled_features();

-- 7. Enable RLS and define security policies

alter table public.tenants enable row level security;
alter table public.tenant_settings enable row level security;
alter table public.tenant_roles enable row level security;
alter table public.user_profiles enable row level security;
alter table public.tenant_members enable row level security;
alter table public.tenant_invitations enable row level security;
alter table public.tenant_billing enable row level security;

-- tenants
create policy "Users can view their own tenants" on public.tenants
  for select using (
    public.is_tenant_member(id)
  );

create policy "Superadmins can manage tenants" on public.tenants
  for all using (
    public.is_superadmin()
  ) with check (
    public.is_superadmin()
  );

-- tenant_settings
create policy "Users can view their own tenant settings" on public.tenant_settings
  for select using (
    public.is_tenant_member(tenant_id)
  );

create policy "Superadmins can insert tenant settings" on public.tenant_settings
  for insert with check (
    public.is_superadmin()
  );

create policy "Tenant owners and superadmins can update settings" on public.tenant_settings
  for update using (
    public.is_tenant_owner(tenant_id)
  ) with check (
    public.is_tenant_owner(tenant_id)
  );

create policy "Superadmins can delete tenant settings" on public.tenant_settings
  for delete using (
    public.is_superadmin()
  );

-- tenant_roles
create policy "Users can view relevant roles" on public.tenant_roles
  for select using (
    tenant_id is null or public.is_tenant_member(tenant_id)
  );

create policy "Owners and superadmins can manage roles" on public.tenant_roles
  for all using (
    (tenant_id is not null and public.is_tenant_owner(tenant_id)) or public.is_superadmin()
  ) with check (
    (tenant_id is not null and public.is_tenant_owner(tenant_id)) or public.is_superadmin()
  );

-- user_profiles
create policy "Authenticated users can view profiles" on public.user_profiles
  for select using (
    auth.role() = 'authenticated'
  );

create policy "Superadmins can manage profiles" on public.user_profiles
  for insert with check (
    public.is_superadmin()
  );

create policy "Users can update own profile" on public.user_profiles
  for update using (
    id = auth.uid() or public.is_superadmin()
  ) with check (
    id = auth.uid() or public.is_superadmin()
  );

create policy "Superadmins can delete profiles" on public.user_profiles
  for delete using (
    public.is_superadmin()
  );

-- tenant_members
create policy "Users can view memberships of their tenants" on public.tenant_members
  for select using (
    public.is_tenant_member(tenant_id)
  );

create policy "Owners and superadmins can manage memberships" on public.tenant_members
  for all using (
    public.is_tenant_owner(tenant_id)
  ) with check (
    public.is_tenant_owner(tenant_id)
  );

-- tenant_invitations
create policy "Relevant users can view invitations" on public.tenant_invitations
  for select using (
    public.is_tenant_member(tenant_id) or email = auth.jwt()->>'email'
  );

create policy "Owners and superadmins can manage invitations" on public.tenant_invitations
  for all using (
    public.is_tenant_owner(tenant_id)
  ) with check (
    public.is_tenant_owner(tenant_id)
  );

-- tenant_billing
create policy "Users can view billing of their tenants" on public.tenant_billing
  for select using (
    public.is_tenant_member(tenant_id)
  );

create policy "Superadmins can manage billing" on public.tenant_billing
  for all using (
    public.is_superadmin()
  ) with check (
    public.is_superadmin()
  );
