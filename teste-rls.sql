-- TESTE DA TRANCA: cole tudo no SQL Editor e execute de uma vez.
-- Cria registros temporários, verifica acessos e desfaz tudo no final.
-- Faça depois de banco.sql e de criar seu usuário com e-mail confirmado.
begin;
insert into public.videos(id,titulo,visivel) values
 ('00000000-0000-4000-8000-000000000091','TESTE PRIVADO',false),
 ('00000000-0000-4000-8000-000000000092','TESTE PUBLICO',true);
insert into public.marcas(id,nome) values('00000000-0000-4000-8000-000000000093','TESTE PRIVADO');

-- Visitante sem login: nenhuma linha privada e apenas vídeo público.
set local role anon;
do $$ begin
 if exists(select 1 from public.marcas) or exists(select 1 from public.calendario)
 or exists(select 1 from public.campanhas) or exists(select 1 from public.marcados)
 or exists(select 1 from public.visitas) or exists(select 1 from public.ideias)
 or exists(select 1 from public.videos where not visivel) then
   raise exception 'FALHOU: visitante leu dados privados';
 end if;
 if not exists(select 1 from public.videos where id='00000000-0000-4000-8000-000000000092') then
   raise exception 'FALHOU: vídeo público não apareceu';
 end if;
 begin
   insert into public.marcas(nome,situacao) values('TESTE NEGADO','cliente');
   raise exception 'FALHOU: visitante criou cliente';
 exception when insufficient_privilege then null; end;
 begin
   update public.videos set titulo='ALTERADO';
   raise exception 'FALHOU: visitante alterou vídeos';
 exception when insufficient_privilege then null; end;
end $$;
insert into public.marcas(nome,situacao) values('TESTE LEAD','lead');
insert into public.visitas(pagina,origem) values('/teste','teste');
reset role;

-- Outra pessoa logada também não pode ler seus dados.
select set_config('request.jwt.claims','{"sub":"00000000-0000-4000-8000-000000000099","role":"authenticated","email":"outra@example.invalid"}',true);
set local role authenticated;
do $$ begin
 if exists(select 1 from public.marcas) or exists(select 1 from public.calendario)
 or exists(select 1 from public.campanhas) or exists(select 1 from public.marcados)
 or exists(select 1 from public.visitas) or exists(select 1 from public.ideias)
 or exists(select 1 from public.videos where not visivel) then
   raise exception 'FALHOU: outra conta leu dados privados';
 end if;
 update public.videos set titulo='ALTERADO' where id='00000000-0000-4000-8000-000000000091';
 if found then raise exception 'FALHOU: outra conta alterou vídeo privado'; end if;
end $$;
reset role;

-- A dona confirmada deve conseguir ler e editar.
do $$ declare dono uuid; begin
 select id into dono from auth.users where lower(email)='bypriscilahonorato.contato@gmail.com' and email_confirmed_at is not null;
 if dono is null then raise exception 'Crie e confirme seu usuário antes de rodar este teste'; end if;
 perform set_config('request.jwt.claims',json_build_object('sub',dono,'role','authenticated')::text,true);
end $$;
set local role authenticated;
do $$ begin
 if not exists(select 1 from public.marcas where id='00000000-0000-4000-8000-000000000093') then raise exception 'FALHOU: a dona não leu seus dados'; end if;
 update public.videos set titulo='TESTE OK' where id='00000000-0000-4000-8000-000000000091';
 if not found then raise exception 'FALHOU: a dona não editou'; end if;
end $$;
reset role;
select 'PASSOU: visitante e outra conta bloqueados; vídeos públicos e acesso da dona funcionando.' as resultado;
rollback;
