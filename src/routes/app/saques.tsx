import { useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { ArrowDownToLine, CheckCircle2 } from "lucide-react";
import { useAuth } from "../../lib/auth";
import { readMerchantData, writeMerchantData, totals, type MerchantData } from "../../lib/merchant-data";
import { PageHeader } from "../../components/ui";

export const Route = createFileRoute("/app/saques")({ component: Withdrawals });

function Withdrawals() {
  const { profile } = useAuth();
  const [data, setData] = useState<MerchantData>();
  const [amount, setAmount] = useState("");
  const [method, setMethod] = useState("");
  const [message, setMessage] = useState("");
  useEffect(() => setData(readMerchantData(profile?.id)), [profile?.id]);
  if (!data) return null;
  const balance = totals(data);

  const submit = (event: React.FormEvent) => {
    event.preventDefault();
    const numericAmount = Number(amount.replace(",", "."));
    if (!method || !Number.isFinite(numericAmount) || numericAmount <= 0 || numericAmount > balance.available) {
      setMessage("Informe um valor válido dentro do saldo disponível.");
      return;
    }
    const next = { ...data, withdrawals: [...data.withdrawals, { id: crypto.randomUUID(), amount: numericAmount, method, status: "pending" as const, createdAt: new Date().toISOString() }] };
    setData(next); writeMerchantData(next, profile?.id); setAmount(""); setMessage("Solicitação registrada e aguardando processamento.");
  };

  return <div>
    <PageHeader eyebrow="LIQUIDAÇÃO" title="Solicitar saque" description="Transfira seu saldo disponível para um método configurado." />
    <div className="withdraw-layout">
      <section className="panel"><div className="balance-highlight"><span>Saldo disponível</span><strong>€ {balance.available.toFixed(2).replace(".", ",")}</strong></div>
        <form className="payment-form" onSubmit={submit}>
          <label className="field-label">Valor do saque<input inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="0,00" /></label>
          <label className="field-label">Método<select value={method} onChange={(e) => setMethod(e.target.value)}><option value="">Selecione</option>{data.methods.map((item) => <option key={item.id} value={item.id}>{item.label} · {item.value}</option>)}</select></label>
          {message && <div className="notice success"><CheckCircle2 size={18} />{message}</div>}
          <button className="primary-button"><ArrowDownToLine size={16} />Solicitar saque</button>
        </form>
      </section>
      <section className="panel"><div className="section-kicker">HISTÓRICO</div><h2>Solicitações</h2>
        {data.withdrawals.length === 0 ? <p className="muted">Nenhum saque solicitado ainda.</p> : data.withdrawals.slice().reverse().map((item) => <div className="activity-row" key={item.id}><div><strong>{data.methods.find((m) => m.id === item.method)?.label || "Método"}</strong><span>{new Date(item.createdAt).toLocaleDateString("pt-PT")}</span></div><b>€ {item.amount.toFixed(2)}</b></div>)}
      </section>
    </div>
  </div>;
}