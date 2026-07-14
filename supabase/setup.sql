-- Kế toán Huyền Trang: dữ liệu kiểm kê dùng chung (bản thử nghiệm)
create table if not exists public.inventory_sessions (
  id text primary key,
  payload jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.inventory_events (
  id bigint generated always as identity primary key,
  session_id text not null references public.inventory_sessions(id) on delete cascade,
  product_code text not null,
  user_id text not null,
  delta integer not null check (delta <> 0),
  action text not null default 'đếm',
  created_at timestamptz not null default now()
);

create index if not exists inventory_events_session_created_at_idx
  on public.inventory_events (session_id, created_at);

alter table public.inventory_sessions enable row level security;
alter table public.inventory_events enable row level security;

-- Chỉ dùng cho giai đoạn test: bất kỳ người dùng nào mở link cũng có thể
-- xem và tham gia đợt kiểm kê. Khi đưa vào dùng thật, thay bằng tài khoản nhân viên.
create policy "test users can read sessions"
  on public.inventory_sessions for select to anon, authenticated using (true);
create policy "test users can create sessions"
  on public.inventory_sessions for insert to anon, authenticated with check (true);
create policy "test users can update sessions"
  on public.inventory_sessions for update to anon, authenticated using (true) with check (true);
create policy "test users can read scan events"
  on public.inventory_events for select to anon, authenticated using (true);
create policy "test users can add scan events"
  on public.inventory_events for insert to anon, authenticated with check (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.inventory_sessions to anon, authenticated;
grant select, insert on public.inventory_events to anon, authenticated;
grant usage, select on sequence public.inventory_events_id_seq to anon, authenticated;

alter publication supabase_realtime add table public.inventory_sessions;
alter publication supabase_realtime add table public.inventory_events;
