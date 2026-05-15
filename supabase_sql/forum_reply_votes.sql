create table if not exists public.votos_respuestas_foro (
  id uuid primary key default gen_random_uuid(),
  id_respuesta uuid not null references public.respuestas_foro(id) on delete cascade,
  id_usuario uuid not null references public.perfiles(id) on delete cascade,
  valor smallint not null check (valor in (-1, 1)),
  creado_el timestamptz not null default now(),
  actualizado_el timestamptz not null default now(),
  unique (id_respuesta, id_usuario)
);

alter table public.votos_respuestas_foro enable row level security;

create policy "Usuarios pueden ver votos de respuestas"
on public.votos_respuestas_foro
for select
to authenticated
using (true);

create policy "Usuarios pueden votar respuestas como ellos mismos"
on public.votos_respuestas_foro
for insert
to authenticated
with check (id_usuario = auth.uid());

create policy "Usuarios pueden actualizar sus votos de respuestas"
on public.votos_respuestas_foro
for update
to authenticated
using (id_usuario = auth.uid())
with check (id_usuario = auth.uid());

create policy "Usuarios pueden eliminar sus votos de respuestas"
on public.votos_respuestas_foro
for delete
to authenticated
using (id_usuario = auth.uid());

create or replace function public.recalcular_votos_respuesta_foro(p_id_respuesta uuid)
returns table (votos_positivos integer, votos_negativos integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  positivos integer;
  negativos integer;
begin
  select
    count(*) filter (where valor = 1)::integer,
    count(*) filter (where valor = -1)::integer
  into positivos, negativos
  from public.votos_respuestas_foro
  where id_respuesta = p_id_respuesta;

  update public.respuestas_foro
  set
    votos_positivos = positivos,
    votos_negativos = negativos
  where id = p_id_respuesta;

  return query select positivos, negativos;
end;
$$;

create or replace function public.votar_respuesta_foro(
  p_id_respuesta uuid,
  p_valor smallint
)
returns table (votos_positivos integer, votos_negativos integer, mi_voto smallint)
language plpgsql
security definer
set search_path = public
as $$
declare
  usuario uuid := auth.uid();
  voto_actual smallint;
  positivos integer;
  negativos integer;
begin
  if usuario is null then
    raise exception 'Debes iniciar sesion para votar.';
  end if;

  if p_valor not in (-1, 1) then
    raise exception 'El voto debe ser 1 o -1.';
  end if;

  if not exists (select 1 from public.respuestas_foro where id = p_id_respuesta) then
    raise exception 'La respuesta no existe.';
  end if;

  select valor
  into voto_actual
  from public.votos_respuestas_foro
  where id_respuesta = p_id_respuesta
    and id_usuario = usuario;

  if voto_actual = p_valor then
    delete from public.votos_respuestas_foro
    where id_respuesta = p_id_respuesta
      and id_usuario = usuario;
    mi_voto := null;
  else
    insert into public.votos_respuestas_foro (
      id_respuesta,
      id_usuario,
      valor,
      actualizado_el
    )
    values (
      p_id_respuesta,
      usuario,
      p_valor,
      now()
    )
    on conflict (id_respuesta, id_usuario)
    do update set
      valor = excluded.valor,
      actualizado_el = now();
    mi_voto := p_valor;
  end if;

  select r.votos_positivos, r.votos_negativos
  into positivos, negativos
  from public.recalcular_votos_respuesta_foro(p_id_respuesta) r;

  return query select positivos, negativos, mi_voto;
end;
$$;

grant execute on function public.votar_respuesta_foro(uuid, smallint) to authenticated;
