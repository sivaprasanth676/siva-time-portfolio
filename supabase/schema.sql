-- SIVA TIME portfolio backend — run once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admin_users where user_id = auth.uid()); $$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

create table if not exists public.site_profile (
  id uuid primary key default gen_random_uuid(),
  full_name text not null default 'Siva Prasanth',
  brand_name text not null default 'SIVA TIME',
  tagline text not null default 'Where Law Meets Technology.',
  bio text not null default 'A law student exploring the intersection of legal systems, emerging technologies and artificial intelligence.',
  education text not null default 'BA LL.B. (Hons.), Vinayaka Mission''s Law School, Chennai',
  location text not null default 'Chennai, Tamil Nadu, India',
  email text,
  linkedin_url text,
  github_url text,
  instagram_url text,
  resume_url text,
  updated_at timestamptz not null default now()
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null default 'PROJECT',
  summary text not null default '',
  body text,
  image_url text,
  project_url text,
  sort_order integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null default 'LEGAL INSIGHT',
  excerpt text not null default '',
  content text,
  slug text unique,
  published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.experiences (
  id uuid primary key default gen_random_uuid(),
  period text not null,
  title text not null,
  kind text not null default 'EXPERIENCE',
  description text not null default '',
  organisation text,
  sort_order integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  subject text not null,
  message text not null,
  status text not null default 'new' check (status in ('new','read','replied','archived')),
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
alter table public.site_profile enable row level security;
alter table public.projects enable row level security;
alter table public.articles enable row level security;
alter table public.experiences enable row level security;
alter table public.messages enable row level security;

-- Explicit table privileges; RLS policies below still decide which rows/actions are allowed.
grant select on public.site_profile, public.projects, public.articles, public.experiences to anon, authenticated;
grant select on public.admin_users to authenticated;
grant insert, update, delete on public.site_profile, public.projects, public.articles, public.experiences, public.messages to authenticated;
grant select, update, delete on public.messages to authenticated;

-- Admin role records are not directly readable/writable from the browser.
create policy "admins can read own admin role" on public.admin_users for select to authenticated using (user_id = auth.uid());

create policy "public can read profile" on public.site_profile for select to anon, authenticated using (true);
create policy "admins manage profile" on public.site_profile for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "public read published projects" on public.projects for select to anon, authenticated using (published = true or public.is_admin());
create policy "admins manage projects" on public.projects for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "public read published articles" on public.articles for select to anon, authenticated using (published = true or public.is_admin());
create policy "admins manage articles" on public.articles for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "public read published experiences" on public.experiences for select to anon, authenticated using (published = true or public.is_admin());
create policy "admins manage experiences" on public.experiences for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Messages are inserted only by the Vercel server using the service role key.
create policy "admins manage messages" on public.messages for all to authenticated using (public.is_admin()) with check (public.is_admin());

insert into public.site_profile (full_name, brand_name, tagline, bio, education, location, email, linkedin_url, github_url, instagram_url)
select 'Siva Prasanth','SIVA TIME','Where Law Meets Technology.','A law student exploring the intersection of legal systems, emerging technologies and artificial intelligence.','BA LL.B. (Hons.), Vinayaka Mission''s Law School, Chennai','Chennai, Tamil Nadu, India','sivaprasanth676@gmail.com','https://www.linkedin.com/in/siva-time/','https://github.com/sivaprasanth676','https://www.instagram.com/siva_time/'
where not exists (select 1 from public.site_profile);

insert into public.projects (title,category,summary,sort_order,published) values
('Law, Policy & Society','ACADEMIC RESEARCH','Research and presentation work exploring Indian legal frameworks, statutory interpretation and contemporary social questions.',1,true),
('AI & Digital Workflows','EXPERIMENTS','Exploring how AI tools can support research, content and everyday productivity.',2,true),
('Design & Content','CREATIVE PRACTICE','Visual communication, editing and creative content for ideas, events and personal projects.',3,true)
on conflict do nothing;

insert into public.experiences (period,title,kind,description,organisation,sort_order,published) values
('ACADEMIC JOURNEY','Vinayaka Mission''s Law School','EDUCATION','BA LL.B. (Hons.) — legal education, academic research, presentations and campus engagement.','Chennai, Tamil Nadu',1,true),
('STUDENT LEADERSHIP','Student Council & Campus Activities','LEADERSHIP & SERVICE','Contributed to student initiatives, sports and cultural activities, event coordination and campus life.','VMLS',2,true),
('INTERNSHIP EXPERIENCE','Legal & Corporate Environments','PROFESSIONAL EXPOSURE','Internship experiences providing exposure to professional work, observation, communication and practical learning.','Tamil Nadu',3,true),
('COMMUNITY ENGAGEMENT','Social Awareness & Volunteering','OUTREACH','Participated in community outreach and awareness initiatives, including legal and social development activities.','Tamil Nadu',4,true)
on conflict do nothing;

-- Optional public image bucket. Keep uploads controlled by admin policy.
insert into storage.buckets (id,name,public) values ('portfolio-media','portfolio-media',true) on conflict (id) do nothing;
create policy "public can view portfolio media" on storage.objects for select to anon, authenticated using (bucket_id = 'portfolio-media');
create policy "admins upload portfolio media" on storage.objects for insert to authenticated with check (bucket_id = 'portfolio-media' and public.is_admin());
create policy "admins update portfolio media" on storage.objects for update to authenticated using (bucket_id = 'portfolio-media' and public.is_admin()) with check (bucket_id = 'portfolio-media' and public.is_admin());
create policy "admins delete portfolio media" on storage.objects for delete to authenticated using (bucket_id = 'portfolio-media' and public.is_admin());
