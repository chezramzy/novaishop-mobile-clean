create extension if not exists pgcrypto;

create table if not exists public.partner_applications (
  id uuid primary key default gen_random_uuid(),
  whatsapp text not null check (length(trim(whatsapp)) >= 8),
  product_description text not null check (length(trim(product_description)) >= 30),
  product_images jsonb not null default '[]'::jsonb,
  applicant_user_id text,
  applicant_email text,
  source text not null default 'mobile_app',
  status text not null default 'new'
    check (status in ('new', 'reviewing', 'approved', 'rejected', 'archived')),
  admin_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists partner_applications_status_idx
  on public.partner_applications(status, created_at desc);

alter table public.partner_applications enable row level security;

create policy "anyone can submit partner applications"
  on public.partner_applications for insert
  to anon, authenticated
  with check (
    status = 'new'
    and jsonb_typeof(product_images) = 'array'
    and jsonb_array_length(product_images) = 3
  );
