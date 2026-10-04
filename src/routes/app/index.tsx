import{createFileRoute}from"@tanstack/react-router";import{useState}from"react";import{Check,Copy,CreditCard,Landmark,Clock3,ShieldAlert,WalletCards}from"lucide-react";import{PageHeader}from"../../components/ui";import{copyText,formatEur,usePlatformSettings,useSellerDashboard,useSellerLedger,whatsappInstructions}from"../../lib/platform";

export const Route=createFileRoute("/app/")({component:Overview});

function Overview(){
  const{settings,loading:settingsLoading}=usePlatformSettings();
  const{data,loading:dashboardLoading,error:dashboardError}=useSellerDashboard();const{data:ledger,loading:ledgerLoading}=useSellerLedger();
  const[copied,setCopied]=useState("");
  const copy=async(kind:string,text:string)=>{if(!text)return;try{await copyText(text);setCopied(kind);window.setTimeout(()=>setCopied(""),1800)}catch{setCopied("")}};
  const configured=Boolean(settings?.initialized_at);
  const copyInstructions=()=>{if(settings)void copy("instructions",whatsappInstructions(settings))};
  return <div><PageHeader eyebrow="VISÃO GERAL" title="Visão geral" description="Resumo da sua conta JaguaPay."/>
    <section className="panel settlement"><div className="section-kicker">RECEBA PAGAMENTOS</div><h2>Dados para receber</h2><p>Todos os vendedores ativos usam os mesmos dados centrais da operação.</p>{settingsLoading?<div className="empty-state compact">Carregando dados…</div>:!configured?<div className="empty-state compact"><strong>Dados de recebimento ainda não configurados</strong><span>O administrador precisa salvar o telefone MB WAY e/ou IBAN central.</span></div>:<><div className="method-grid"><ReceiveCard icon={<CreditCard size={17}/>} title="MB WAY" value={settings?.mbway_phone||null} copied={copied==="mbway"} onCopy={()=>void copy("mbway",settings?.mbway_phone||"")}/><ReceiveCard icon={<Landmark size={17}/>} title="IBAN" value={settings?.central_iban||null} copied={copied==="iban"} onCopy={()=>void copy("iban",settings?.central_iban||"")}/></div><div className="copy-instructions"><button className="secondary-button" onClick={copyInstructions}><Copy size={15}/>{copied==="instructions"?"Instruções copiadas":"Copiar instruções para WhatsApp"}</button></div></>}</section>
    <div className="stats-grid"><Stat icon={<WalletCards size={16}/>} label="SALDO DISPONÍVEL" value={formatEur(data.available_balance_eur)}/><Stat icon={<Clock3 size={16}/>} label="SALDO PENDENTE" value={formatEur(data.pending_balance_eur)}/><Stat icon={<CreditCard size={16}/>} label="VOLUME APROVADO" value={formatEur(data.approved_volume_eur)}/><Stat icon={<ShieldAlert size={16}/>} label="VALOR SOB RISCO" value={formatEur(data.at_risk_eur)}/><Stat icon={<WalletCards size={16}/>} label="RESERVADO EM SAQUES" value={formatEur(data.reserved_withdrawals_eur)}/></div>
    {dashboardError&&<div className="notice">{dashboardError}</div>}
    <section className="panel activity"><div className="section-kicker">EXTRATO</div><h2>Extrato individual</h2>{ledgerLoading?<div className="empty-state compact">Carregando seu extrato…</div>:ledger.length===0?<div className="empty-state compact"><strong>Sem movimentações</strong><span>Os lançamentos reais aparecerão aqui quando houver pagamentos ou saques.</span></div>:ledger.map(entry=><div className="activity-row" key={entry.kind+"-"+entry.id}><div><strong>{entry.kind==="payment"?"Pagamento":"Solicitação de saque"}</strong><span>{new Date(entry.created_at).toLocaleString("pt-BR")}{entry.reference?" · "+entry.reference:""}</span></div><div><strong>{entry.amount_eur>=0?"+":"−"} {formatEur(Math.abs(entry.amount_eur))}</strong><span>{entry.status}</span></div></div>)}</section>
  </div>
}

function ReceiveCard({icon,title,value,copied,onCopy}:{icon:React.ReactNode;title:string;value:string|null;copied:boolean;onCopy:()=>void}){return <div className="method-card"><div className="method-top"><div className="method-icon">{icon}</div><div><strong>{title}</strong><small>CENTRAL JAGUAPAY</small></div></div><div className="method-value"><b>{value||"Não configurado"}</b>{value&&<button className="icon-button" onClick={onCopy} aria-label={"Copiar "+title}>{copied?<Check size={15}/>:<Copy size={15}/>}</button>}</div></div>}

function Stat({icon,label,value}:{icon:React.ReactNode;label:string;value:string}){return <div className="stat-card"><span>{label}</span><div>{icon}</div><strong>{value}</strong></div>}
