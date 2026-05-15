create table if not exists public.tokens_push (
  id uuid primary key default gen_random_uuid(),
  id_usuario uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  plataforma text not null default 'unknown',
  activo boolean not null default true,
  creado_el timestamptz not null default now(),
  actualizado_el timestamptz not null default now()
);

alter table public.tokens_push enable row level security;

create policy "Usuarios pueden ver sus tokens push"
on public.tokens_push
for select
to authenticated
using (id_usuario = auth.uid());

create policy "Usuarios pueden registrar sus tokens push"
on public.tokens_push
for insert
to authenticated
with check (id_usuario = auth.uid());

create policy "Usuarios pueden actualizar sus tokens push"
on public.tokens_push
for update
to authenticated
using (id_usuario = auth.uid())
with check (id_usuario = auth.uid());

create policy "Usuarios pueden eliminar sus tokens push"
on public.tokens_push
for delete
to authenticated
using (id_usuario = auth.uid());
