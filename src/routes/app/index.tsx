import { useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { Building2, CalendarDays, CheckCircle2, Clock3, Copy, Euro, ShieldAlert, WalletCards } from "lucide-react";
import { useAuth } from "../../lib/auth";
import { readMerchantData, totals, type MerchantData } from "../../lib/merchant-data";
import { PageHeader } from "../../components/ui";

export const Route = createFileRoute("/app/")({ component: Overview });

const money = (value: number) => new Intl.NumberFormat("pt-PT", { style: "currency", currency: "EUR" }).format(value);

function Overview() {
  const { profile } = useAuth();
  const [data, setData] = useState<MerchantData>();
  useEffect(() => setData(readMerchantData(profile?.id)), [profile?.id]);
  if (!data) return null;
  const balance = totals(data);

  return <div>
    <PageHeader eyebrow="VISÃO GERAL" title={`Olá, ${profile?.full_name?.split(" ")[0] || "vendedor"}`} description="Resumo da sua conta Jaguar Pay."
      action={<div className="overview-sync"><span><CalendarDays size={15} />30 dias</span><span className="sync-ok">● SYNC OK</span></div>} />

    <section className="settlement panel">
      <div className="section-kicker">RECEBER PAGAMENTOS</div>
      <h2>Dados de Liquidação</h2>
      <p>Utilize os canais abaixo para processar vendas. Cada transação é registrada para conciliação.</p>
      <div className="method-grid">
        {data.methods.map((method) => <div className="method-card" key={method.id}>
          <div className="method-top">
            <div className="method-icon">{method.type === "MBWAY" ? <WalletCards size={18} /> : <Building2 size={18} />}</div>
            <div><strong>{method.label}</strong><small>PT · EUR</small></div>
            {method.primary && <span className="primary-pill">PRIMARY</span>}
          </div>
          <div className="method-value"><b>{method.value}</b><button className="icon-button" onClick={() => navigator.clipboard?.writeText(method.value)}><Copy size={15} /></button></div>
        </div>)}
      </div>
    </section>

    <div className="stats-grid">
      <Stat label="SALDO DISPONÍVEL" value={money(balance.available)} icon={<WalletCards size={17} />} />
      <Stat label="SALDO PENDENTE" value={money(balance.pending)} icon={<Clock3 size={17} />} />
      <Stat label="VOLUME APROVADO" value={money(balance.approved)} icon={<Euro size={17} />} />
      <Stat label="VALOR SOB RISCO" value={money(balance.risk)} icon={<ShieldAlert size={17} />} />
    </div>

    <section className="panel activity">
      <div className="section-kicker">ATIVIDADE</div><h2>Últimos lançamentos</h2>
      {data.payments.slice().reverse().slice(0, 5).map((payment) => <div className="activity-row" key={payment.id}>
        <div><strong>{payment.customer}</strong><span>{new Date(payment.createdAt).toLocaleDateString("pt-PT")}</span></div>
        <div><b>{money(payment.amount)}</b>{payment.status === "approved" ? <span className="status-ok"><CheckCircle2 size={13} />Aprovado</span> : <span className="status-pending"><Clock3 size={13} />Pendente</span>}</div>
      </div>)}
    </section>
  </div>;
}

function Stat({ label, value, icon }: { label: string; value: string; icon: React.ReactNode }) {
  return <div className="stat-card"><span>{label}</span><div>{icon}</div><strong>{value}</strong></div>;
}
