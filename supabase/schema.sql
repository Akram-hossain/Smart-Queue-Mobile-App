-- =============================================================================
-- SemesterMate — Supabase schema
-- Paste the entire file into Supabase Studio: SQL Editor -> New query -> Run.
-- Safe to re-run (idempotent via "if not exists" / "drop policy if exists").
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. profiles
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  full_name       text        not null,
  email           text        not null,
  department      text,
  semester        text,
  university      text,
  avatar_url      text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists profiles_email_idx on public.profiles(email);

-- -----------------------------------------------------------------------------
-- 2. tasks (CT / LAB / VIVA / ASSIGNMENT / FINAL)
-- -----------------------------------------------------------------------------
create table if not exists public.tasks (
  id              uuid        primary key default gen_random_uuid(),
  user_id         uuid        not null references auth.users(id) on delete cascade,
  title           text        not null,
  description     text,
  type            text        not null check (type in ('CT','LAB','VIVA','ASSIGNMENT','FINAL')),
  due_date        timestamptz not null,
  priority        text        not null default 'medium' check (priority in ('low','medium','high')),
  status          text        not null default 'pending' check (status in ('pending','in_progress','completed')),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists tasks_user_due_idx   on public.tasks(user_id, due_date);
create index if not exists tasks_user_status_idx on public.tasks(user_id, status);
create index if not exists tasks_user_type_idx   on public.tasks(user_id, type);

-- -----------------------------------------------------------------------------
-- 3. attendance
-- -----------------------------------------------------------------------------
create table if not exists public.attendance (
  id                uuid        primary key default gen_random_uuid(),
  user_id           uuid        not null references auth.users(id) on delete cascade,
  subject_name      text        not null,
  total_classes     integer     not null default 0 check (total_classes >= 0),
  attended_classes  integer     not null default 0 check (attended_classes >= 0),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  check (attended_classes <= total_classes)
);

create index if not exists attendance_user_idx on public.attendance(user_id);

-- -----------------------------------------------------------------------------
-- 4. semester_fees
-- -----------------------------------------------------------------------------
create table if not exists public.semester_fees (
  id              uuid        primary key default gen_random_uuid(),
  user_id         uuid        not null references auth.users(id) on delete cascade,
  semester_label  text        not null,
  total_fee       numeric(12,2) not null check (total_fee >= 0),
  paid_amount     numeric(12,2) not null default 0 check (paid_amount >= 0),
  due_date        date        not null,
  payment_note    text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists semester_fees_user_idx on public.semester_fees(user_id);

-- -----------------------------------------------------------------------------
-- 5. gpa_records
-- -----------------------------------------------------------------------------
create table if not exists public.gpa_records (
  id              uuid        primary key default gen_random_uuid(),
  user_id         uuid        not null references auth.users(id) on delete cascade,
  semester_label  text        not null,
  course_name     text        not null,
  course_code     text,
  credit          numeric(4,2) not null check (credit >= 0),
  grade           text        not null check (grade in ('A+','A','A-','B+','B','B-','C+','C','D','F')),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists gpa_records_user_idx     on public.gpa_records(user_id);
create index if not exists gpa_records_user_sem_idx on public.gpa_records(user_id, semester_label);

-- -----------------------------------------------------------------------------
-- updated_at triggers
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare t text;
begin
  for t in select unnest(array['profiles','tasks','attendance','semester_fees','gpa_records']) loop
    execute format('drop trigger if exists set_updated_at on public.%I;', t);
    execute format(
      'create trigger set_updated_at before update on public.%I '
      'for each row execute function public.set_updated_at();', t);
  end loop;
end $$;

-- -----------------------------------------------------------------------------
-- Auto-create profile row when a user signs up
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email, department, semester, university)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    new.email,
    new.raw_user_meta_data->>'department',
    new.raw_user_meta_data->>'semester',
    new.raw_user_meta_data->>'university'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- =============================================================================
-- Row Level Security
-- =============================================================================
alter table public.profiles      enable row level security;
alter table public.tasks         enable row level security;
alter table public.attendance    enable row level security;
alter table public.semester_fees enable row level security;
alter table public.gpa_records   enable row level security;

-- profiles
drop policy if exists "profiles_select_own"  on public.profiles;
drop policy if exists "profiles_insert_own"  on public.profiles;
drop policy if exists "profiles_update_own"  on public.profiles;
create policy "profiles_select_own"  on public.profiles for select using (auth.uid() = id);
create policy "profiles_insert_own"  on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own"  on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- generic "user owns this row" policies for the other tables
do $$
declare t text;
begin
  for t in select unnest(array['tasks','attendance','semester_fees','gpa_records']) loop
    execute format('drop policy if exists "%1$s_select_own" on public.%1$I;', t);
    execute format('drop policy if exists "%1$s_insert_own" on public.%1$I;', t);
    execute format('drop policy if exists "%1$s_update_own" on public.%1$I;', t);
    execute format('drop policy if exists "%1$s_delete_own" on public.%1$I;', t);

    execute format(
      'create policy "%1$s_select_own" on public.%1$I for select using (auth.uid() = user_id);', t);
    execute format(
      'create policy "%1$s_insert_own" on public.%1$I for insert with check (auth.uid() = user_id);', t);
    execute format(
      'create policy "%1$s_update_own" on public.%1$I for update using (auth.uid() = user_id) with check (auth.uid() = user_id);', t);
    execute format(
      'create policy "%1$s_delete_own" on public.%1$I for delete using (auth.uid() = user_id);', t);
  end loop;
end $$;

-- Done. You can verify with:
--   select tablename, policyname from pg_policies where schemaname = 'public';
