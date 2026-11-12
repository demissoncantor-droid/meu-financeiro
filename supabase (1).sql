-- Meu Controle Financeiro: tabela e funções (cole tudo no SQL Editor do Supabase e clique em Run)

create table if not exists public.registros (
  familia   text        not null,
  colecao   text        not null,
  id        text        not null,
  dados     jsonb       not null,
  atualizado timestamptz not null default now(),
  primary key (familia, colecao, id)
);

-- Ninguém acessa a tabela diretamente; só pelas funções abaixo, que exigem o código da família.
alter table public.registros enable row level security;
revoke all on table public.registros from anon, authenticated;

create or replace function public.listar_registros(p_familia text)
returns table(colecao text, id text, dados jsonb)
language plpgsql security definer set search_path = public as $$
begin
  if p_familia !~ '^[0-9]{4,12}$' then raise exception 'codigo invalido'; end if;
  return query select r.colecao, r.id, r.dados from public.registros r where r.familia = p_familia;
end $$;

create or replace function public.salvar_registro(p_familia text, p_colecao text, p_id text, p_dados jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_familia !~ '^[0-9]{4,12}$' then raise exception 'codigo invalido'; end if;
  insert into public.registros (familia, colecao, id, dados, atualizado)
  values (p_familia, p_colecao, p_id, p_dados, now())
  on conflict (familia, colecao, id) do update set dados = excluded.dados, atualizado = now();
end $$;

create or replace function public.apagar_registro(p_familia text, p_colecao text, p_id text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_familia !~ '^[0-9]{4,12}$' then raise exception 'codigo invalido'; end if;
  delete from public.registros where familia = p_familia and colecao = p_colecao and id = p_id;
end $$;

grant execute on function public.listar_registros(text) to anon, authenticated;
grant execute on function public.salvar_registro(text, text, text, jsonb) to anon, authenticated;
grant execute on function public.apagar_registro(text, text, text) to anon, authenticated;
