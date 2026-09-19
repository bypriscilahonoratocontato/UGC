/* ============================================================
   CONEXAO COM O BANCO (Supabase)

   Este e o unico arquivo onde o endereco e a chave ficam escritos.
   Todas as paginas (portfolio, login e admin) usam ele.

   A chave abaixo e a chave PUBLICA. Ela pode ficar visivel,
   porque sozinha ela nao abre nada: quem protege os dados de
   verdade sao as regras de RLS que estao no banco.sql.

   NUNCA coloque aqui a chave secreta (service_role).
   ============================================================ */

window.BANCO = {
  url: "https://nonoflskftnlxvuwvczy.supabase.co",
  chavePublica: "sb_publishable_KT8IADsvYw-qpuIWXOo8KA_XG-22pJG",
  emailDona: "bypriscilahonorato.contato@gmail.com"
};

/* Cria a conexao. Se a biblioteca do Supabase nao tiver carregado
   (internet caiu, CDN fora do ar), o site nao quebra: fica null e
   cada pagina decide o que mostrar. */
window.sb = (function(){
  try {
    if(!window.supabase || !window.supabase.createClient) return null;
    return window.supabase.createClient(window.BANCO.url, window.BANCO.chavePublica);
  } catch(err){
    return null;
  }
})();

/* ============================================================
   AJUDANTES USADOS PELO PAINEL
   ============================================================ */
window.BancoUtil = {

  /* Le uma tabela sem nunca derrubar a pagina.
     Se a tabela nao existir ou der qualquer erro, devolve uma
     lista vazia mais um aviso em portugues, e o painel segue. */
  async ler(tabela, montarConsulta){
    if(!window.sb){
      return { dados: [], erro: "Nao consegui falar com o banco de dados agora." };
    }
    try {
      let dados = [];
      for(let inicio=0; ; inicio+=1000){
        let consulta=window.sb.from(tabela).select("*");
        if(typeof montarConsulta === "function") consulta=montarConsulta(consulta);
        const {data,error}=await consulta.range(inicio,inicio+999);
        if(error) return {dados:[],erro:window.BancoUtil.traduzirErro(error,tabela)};
        dados=dados.concat(data||[]);
        if(!data || data.length<1000) break;
      }
      const campos={videos:['titulo','link','nicho','formato','marca','destaque','ordem','visivel'],marcas:['nome','instagram','email','telefone','situacao','obs','ultimo_contato'],calendario:['titulo','marca','tipo','data','status'],campanhas:['campanha','cliente','tipo','status','qtd','valor','prazo','pagamento','ativa','favorita'],marcados:['chave','marcado'],visitas:['data','pagina','origem'],ideias:['titulo','descricao','nicho','status','origem','trello_id']};
      const faltam=dados.length?(campos[tabela]||[]).filter(c=>!(c in dados[0])):[];
      return {dados,erro:faltam.length?'Faltam campos em '+tabela+': '+faltam.join(', ')+'. As outras abas continuam disponíveis.':null};
    } catch(err){
      return { dados: [], erro: window.BancoUtil.traduzirErro(err, tabela) };
    }
  },

  /* Grava (inserir, atualizar ou apagar) sem derrubar a pagina. */
  async gravar(tabela, executar){
    if(!window.sb){
      return { ok: false, dados: null, erro: "Nao consegui falar com o banco de dados agora." };
    }
    try {
      const { data, error } = await executar(window.sb.from(tabela));
      if(error) return { ok: false, dados: null, erro: window.BancoUtil.traduzirErro(error, tabela) };
      return { ok: true, dados: data, erro: null };
    } catch(err){
      return { ok: false, dados: null, erro: window.BancoUtil.traduzirErro(err, tabela) };
    }
  },

  /* Transforma o erro tecnico em uma frase que da para entender. */
  traduzirErro(erro, tabela){
    const texto = String((erro && (erro.message || erro.hint || erro.details)) || erro || "");
    const codigo = (erro && erro.code) || "";

    if(codigo === "42P01" || codigo === "PGRST205" || /not find the table/i.test(texto)){
      return "A tabela \"" + tabela + "\" ainda nao existe no banco. Rode o arquivo banco.sql no Supabase.";
    }
    if(codigo === "42703" || codigo === "PGRST204" || /column .* does not exist/i.test(texto)){
      return "Falta uma coluna na tabela \"" + tabela + "\". Confira a atualização da estrutura no arquivo banco.sql.";
    }
    if(codigo === "42501" || /row-level security|permission denied/i.test(texto)){
      return "O banco recusou o acesso a \"" + tabela + "\". Confira se voce entrou com o seu e-mail.";
    }
    if(codigo === "23505" || /duplicate key/i.test(texto)){
      return "Esse registro ja existe.";
    }
    if(/Failed to fetch|NetworkError|network/i.test(texto)){
      return "Sem conexao com o banco agora. Confira a sua internet.";
    }
    return "Nao consegui carregar \"" + tabela + "\" agora.";
  },

  /* Devolve a sessao aberta, ou null. */
  async sessao(){
    if(!window.sb) return null;
    try {
      const { data } = await window.sb.auth.getSession();
      return (data && data.session) ? data.session : null;
    } catch(err){
      return null;
    }
  },

  /* Encerra a sessao. */
  async sair(){
    if(!window.sb) return;
    const {error}=await window.sb.auth.signOut({scope:"local"});
    if(error) throw error;
  },

  /* Data no formato do banco (2026-09-19). */
  paraISO(data){
    const d = (data instanceof Date) ? data : new Date(data);
    if(isNaN(d.getTime())) return null;
    const mes = String(d.getMonth() + 1).padStart(2, "0");
    const dia = String(d.getDate()).padStart(2, "0");
    return d.getFullYear() + "-" + mes + "-" + dia;
  },

  /* Data do jeito que a gente le (19/09/2026). */
  paraBR(iso){
    if(!iso) return "";
    const partes = String(iso).slice(0, 10).split("-");
    if(partes.length !== 3) return "";
    return partes[2] + "/" + partes[1] + "/" + partes[0];
  },

  /* Dinheiro em reais, sempre com duas casas. */
  emReais(valor){
    const numero = Number(valor);
    const seguro = isFinite(numero) ? numero : 0;
    return seguro.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  },

  /* Divisao que nunca devolve NaN nem quebra quando nao ha dados. */
  dividir(cima, baixo){
    const a = Number(cima), b = Number(baixo);
    if(!isFinite(a) || !isFinite(b) || b === 0) return 0;
    return a / b;
  },

  /* Protege contra texto com < ou > vindo do banco. */
  escapar(texto){
    return String(texto === null || texto === undefined ? "" : texto)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }
};

/* Aceita somente links de vídeo com protocolo seguro. */
window.BancoUtil.urlSegura=function(valor){try{const u=new URL(valor);return u.protocol==='https:'||u.protocol==='http:'?u.href:'';}catch(e){return '';}};
