-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Create USERS table (Public profile linked to Auth)
create table if not exists public.users (
  id uuid references auth.users on delete cascade not null primary key,
  email text not null,
  role text not null check (role in ('patient', 'doctor', 'admin')),
  full_name text,
  profile_image text,
  status text default 'active' check (status in ('active', 'suspended', 'pending')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for users
alter table public.users enable row level security;

-- Policies for users (Use DO blocks to avoid "already exists" errors for policies)
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'Public profiles are viewable by everyone') then
    create policy "Public profiles are viewable by everyone" on public.users for select using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Users can insert their own profile') then
    create policy "Users can insert their own profile" on public.users for insert with check (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Users can update own profile') then
    create policy "Users can update own profile" on public.users for update using (auth.uid() = id);
  end if;
end
$$;

-- 2. Create DOCTORS table
create table if not exists public.doctors (
  id uuid references public.users(id) on delete cascade not null primary key,
  specialization text,
  experience_years int default 0,
  medical_license text, -- New field
  clinic_name text,     -- New field
  consultation_fee numeric default 0,
  about text,
  is_verified boolean default false,
  verification_status text default 'pending' check (verification_status in ('pending', 'verified', 'rejected')),
  rating numeric default 0,
  total_consultations int default 0,
  availability jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for doctors
alter table public.doctors enable row level security;

-- Policies for doctors
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'Doctors are viewable by everyone') then
    create policy "Doctors are viewable by everyone" on public.doctors for select using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Doctors can update own profile') then
    create policy "Doctors can update own profile" on public.doctors for update using (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Doctors can insert own profile') then
    create policy "Doctors can insert own profile" on public.doctors for insert with check (auth.uid() = id);
  end if;
end
$$;

-- 3. Create PATIENTS table
create table if not exists public.patients (
  id uuid references public.users(id) on delete cascade not null primary key,
  date_of_birth date,
  gender text,
  medical_history text[],
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for patients
alter table public.patients enable row level security;

-- Policies for patients
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'Patients viewable by self and doctors') then
    create policy "Patients viewable by self and doctors" on public.patients
      for select using (auth.uid() = id or exists (
        select 1 from public.users where id = auth.uid() and role = 'doctor'
      ));
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Patients can update own profile') then
    create policy "Patients can update own profile" on public.patients for update using (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Patients can insert own profile') then
    create policy "Patients can insert own profile" on public.patients for insert with check (auth.uid() = id);
  end if;
end
$$;

-- 4. Create CONSULTATIONS table
create table if not exists public.consultations (
  id uuid default uuid_generate_v4() primary key,
  patient_id uuid references public.patients(id) not null,
  doctor_id uuid references public.doctors(id) not null,
  scheduled_at timestamp with time zone not null,
  status text default 'scheduled' check (status in ('scheduled', 'ongoing', 'completed', 'cancelled')),
  fee numeric not null,
  symptoms text,
  prescription text,
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for consultations
alter table public.consultations enable row level security;

-- Policies for consultations
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'Users can view own consultations') then
    create policy "Users can view own consultations" on public.consultations
      for select using (auth.uid() = patient_id or auth.uid() = doctor_id);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Patients can create consultations') then
    create policy "Patients can create consultations" on public.consultations for insert with check (auth.uid() = patient_id);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'Doctors can update their consultations') then
    create policy "Doctors can update their consultations" on public.consultations for update using (auth.uid() = doctor_id);
  end if;
end
$$;

-- 5. FUNCTION to handle new user signup automatically
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  -- Create the basic user profile
  insert into public.users (id, email, role, full_name, status)
  values (
    new.id, 
    new.email, 
    coalesce(new.raw_user_meta_data->>'role', 'patient'),
    new.raw_user_meta_data->>'full_name',
    'active'
  )
  on conflict (id) do update set
    email = excluded.email,
    role = excluded.role,
    full_name = excluded.full_name;

  -- Create role-specific record
  if (new.raw_user_meta_data->>'role') = 'doctor' then
    insert into public.doctors (id, specialization, experience_years, medical_license, clinic_name)
    values (
      new.id,
      coalesce(new.raw_user_meta_data->>'specialization', ''),
      coalesce((new.raw_user_meta_data->>'experience')::int, 0),
      new.raw_user_meta_data->>'medical_license',
      new.raw_user_meta_data->>'clinic_name'
    )
    on conflict (id) do update set
      specialization = excluded.specialization,
      experience_years = excluded.experience_years,
      medical_license = excluded.medical_license,
      clinic_name = excluded.clinic_name;
  elsif (new.raw_user_meta_data->>'role') = 'patient' then
    insert into public.patients (id, gender)
    values (
      new.id,
      coalesce(new.raw_user_meta_data->>'gender', 'Not specified')
    )
    on conflict (id) do nothing;
  end if;

  return new;
end;
$$ language plpgsql security definer;

-- Trigger to call the function
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
