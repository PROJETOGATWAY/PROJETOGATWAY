import { useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { ArrowRight, CheckCircle2 } from "lucide-react";
import { useAuth } from "../../lib/auth";
import { readMerchantData, writeMerchantData, type MerchantData } from "../../lib/merchant-data";
import { PageHeader } from "../../components/ui";

export const Route = createFileRoute("/app/pagamentos")({ component: Payments });

function Payments() {
  const { profile } = useAuth();
  const [data, setData] = useState<MerchantData>();
  const [customer, setCustomer] = useState("");
  const [amount, setAmount] = useState("");
  const [done, setDone] = useState(false);
  useEffect(() => setData(readMerchantData(profile?.id)), [profile?.id]);
  if (!data) return null;

  const submit = (event: React.FormEvent) => {
    event.preventDefault();
    const numericAmount = Number(amount.replace(",", "."));
    if (!customer.trim() || !Number.isFinite(numericAmount) || numericAmount <= 0) return;
    const next = { ...data, payments: [...data.payments, { id: crypto.randomUUID(), customer: customer.trim(), amount: numericAmount, status: "pending" as const, createdAt: new Date().toISOString() }] };
    setData(next); writeMerchantData(next, profile?.id); setCustomer(""); setAmount(""); setDone(true);
  };

  return <div>
    <PageHeader eyebrow="RECEBER" title="Lançar pagamento" description="Registre uma nova venda para acompanhar a liquidação." />
    <div className="payment-layout">
      <section className="panel"><form className="payment-form" onSubmit={submit}>
        <label className="field-label">Cliente / referência<input required value={customer} onChange={(e) => setCustomer(e.target.value)} placeholder="Nome do cliente ou referência" /></label>
        <label className="field-label">Valor (EUR)<input required inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="0,00" /></label>
        <div className="payment-info"><span>Liquidação</span><strong>Saldo pendente após registro</strong></div>
        {done && <div className="notice success"><CheckCircle2 size={18} />Pagamento lançado e aguardando aprovação.</div>}
        <button className="primary-button" type="submit">Lançar pagamento <ArrowRight size={16} /></button>
      </form></section>
      <section className="panel"><div className="section-kicker">MÉTODOS DISPONÍVEIS</div><h2>Receba com os métodos configurados</h2>
        {data.methods.map((method) => <div className="mini-method" key={method.id}><span>{method.type}</span><strong>{method.value}</strong></div>)}
      </section>
    </div>
  </div>;
}