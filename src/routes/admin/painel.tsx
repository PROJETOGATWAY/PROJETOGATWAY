import{createFileRoute,Link}from"@tanstack/react-router";import{useEffect,useState}from"react";import{ArrowRight,BadgePercent,Euro,TrendingUp,Wallet}from"lucide-react";import{PageHeader}from"../../components/ui";import{formatEur,getCounterOperationOverview,getMyCounterOverview,listAdminPayments,type PaymentRecord}from"../../lib/platform";

export const Route=createFileRoute("/admin/painel")({
  head:()=>({meta:[
    {title:"Painel do Contador — JaguaPay"},
    {name:"description",content:"Resumo operacional e de comissões do contador na JaguaPay."},
    {property:"og:title",content:"Painel do Contador — JaguaPay"},
    {property:"og:description",content:"Resumo operacional e de comissões do contador na JaguaPay."},
    {property:"og:type",content:"website"},
    {name:"twitter:card",content:"summary"},
  ]}),
  component:CounterDashboardPage,
});

type Overview={percent:number;platform_fee_percent:number;jaguapay_gross_eur:number;jaguapay_fees_eur:number;total_accrued_eur:number};

function CounterDashboardPage(){
  const[overview,setOverview]=useState<Overview|null>(null);
  const[approvedGross,setApprovedGross]=useState(0);
  const[pending,setPending]=useState<PaymentRecord[]>([]);
  const[recent,setRecent]=useState<PaymentRecord[]>([]);
  const[error,setError]=useState("");
  const[loading,setLoading]=useState(true);

  useEffect(()=>{(async()=>{
    try{
      setLoading(true);
      const[ov,op,pend,appr]=await Promise.all([
        getMyCounterOverview(),
        getCounterOperationOverview(),
        listAdminPayments("pending"),
        listAdminPayments("approved"),
      ]);
      setOverview(ov);
      setApprovedGross(op.approved_gross_eur);
      setPending(pend);
      setRecent(appr.slice(0,8));
      setError("");
    }catch{setError("Não foi possível carregar o painel do contador.")}
    finally{setLoading(false)}
  })()},[]);

  if(loading)return <div className="loading-screen"><div className="spinner"/><span>Carregando painel…</span></div>;

  return <div className="counter-dashboard">
    <PageHeader eyebrow="CONTADOR" title="Painel do Contador" description="Resumo do que entrou na JaguaPay e da sua comissão."/>
    {error&&<div className="alert error">{error}</div>}

    <div className="stats-grid">
      <div className="stat-card"><span>ENTROU NA JAGUAPAY (BRUTO APROVADO)</span><div><TrendingUp size={18}/></div><strong>{formatEur(approvedGross)}</strong></div>
      <div className="stat-card"><span>TAXAS JAGUAPAY ({overview?overview.platform_fee_percent:0}%)</span><div><Euro size={18}/></div><strong>{formatEur(overview?.jaguapay_fees_eur||0)}</strong></div>
      <div className="stat-card counter-overview-card"><span>SUA PORCENTAGEM</span><div><BadgePercent size={18}/></div><strong>{overview?.percent||0}%</strong><small>sobre o valor bruto de cada venda aprovada</small></div>
      <div className="stat-card counter-overview-card"><span>VOCÊ JÁ ACUMULOU</span><div><Wallet size={18}/></div><strong>{formatEur(overview?.total_accrued_eur||0)}</strong><small>comissões de vendas aprovadas</small></div>
    </div>

    <div className="panel">
      <div className="panel-head">
        <div><h2>Pagamentos aguardando análise</h2><p>{pending.length} {pending.length===1?"pagamento pendente":"pagamentos pendentes"}</p></div>
        <Link to="/admin/pagamentos" className="btn-primary">Abrir fila de análise <ArrowRight size={15}/></Link>
      </div>
      {pending.length===0?<p className="muted">Nenhum pagamento aguardando análise no momento.</p>:
      <div className="table-wrap"><table className="data-table"><thead><tr><th>Código</th><th>Valor</th><th>Método</th><th>Enviado em</th></tr></thead><tbody>
        {pending.slice(0,5).map(p=><tr key={p.id}><td>{p.payment_code}</td><td>{formatEur(p.gross_amount_eur)}</td><td>{p.payment_method==="mbway"?"MB WAY":"IBAN"}</td><td>{new Date(p.submitted_at||p.created_at).toLocaleString("pt-PT")}</td></tr>)}
      </tbody></table></div>}
    </div>

    <div className="panel">
      <div className="panel-head"><div><h2>Últimas vendas aprovadas</h2><p>Sua comissão é calculada sobre essas vendas.</p></div></div>
      {recent.length===0?<p className="muted">Nenhuma venda aprovada ainda.</p>:
      <div className="table-wrap"><table className="data-table"><thead><tr><th>Código</th><th>Valor bruto</th><th>Taxa JaguaPay</th><th>Aprovado em</th></tr></thead><tbody>
        {recent.map(p=><tr key={p.id}><td>{p.payment_code}</td><td>{formatEur(p.gross_amount_eur)}</td><td>{formatEur(p.fee_amount_eur)}</td><td>{p.approved_at?new Date(p.approved_at).toLocaleString("pt-PT"):"—"}</td></tr>)}
      </tbody></table></div>}
    </div>

    <div className="panel">
      <div className="panel-head"><div><h2>Sua comissão em detalhes</h2><p>Veja o histórico completo de comissões por venda.</p></div>
      <Link to="/app/remuneracao" className="btn-secondary">Minha comissão <ArrowRight size={15}/></Link></div>
    </div>
  </div>
}
