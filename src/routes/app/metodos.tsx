import { useEffect, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { Building2, Check, Copy, Plus, WalletCards } from "lucide-react";
import { useAuth } from "../../lib/auth";
import { readMerchantData, writeMerchantData, type MerchantData, type WithdrawalMethod } from "../../lib/merchant-data";
import { PageHeader } from "../../components/ui";

export const Route = createFileRoute("/app/metodos")({ component: Methods });

function Methods() {
  const { profile } = useAuth();
  const [data, setData] = useState<MerchantData>();
  const [type, setType] = useState<"MBWAY" | "IBAN">("MBWAY");
  const [value, setValue] = useState("");
  useEffect(() => setData(readMerchantData(profile?.id)), [profile?.id]);
  if (!data) return null;

  const add = () => {
    if (!value.trim()) return;
    const method: WithdrawalMethod = { id: crypto.randomUUID(), type, label: type, value: value.trim(), currency: "EUR" };
    const next = { ...data, methods: [...data.methods, method] };
    setData(next); writeMerchantData(next, profile?.id); setValue("");
  };
  const setPrimary = (id: string) => {
    const next = { ...data, methods: data.methods.map((method) => ({ ...method, primary: method.id === id })) };
    setData(next); writeMerchantData(next, profile?.id);
  };

  return <div>
    <PageHeader eyebrow="RECEBIMENTO" title="Métodos de saque" description="Configure os canais usados para receber e liquidar seus valores." />
    <div className="method-page-grid">
      <section className="panel"><div className="section-kicker">CONFIGURADOS</div><h2>Contas de recebimento</h2>
        {data.methods.map((method) => <div className="configured-method" key={method.id}>
          <div className="method-icon">{method.type === "MBWAY" ? <WalletCards size={18} /> : <Building2 size={18} />}</div>
          <div className="configured-info"><strong>{method.label}</strong><span>{method.value}</span><small>EUR · {method.primary ? "Principal" : "Disponível"}</small></div>
          <button className="icon-button" onClick={() => navigator.clipboard?.writeText(method.value)}><Copy size={15} /></button>
          {method.primary ? <span className="primary-pill"><Check size={12} />Principal</span> : <button className="secondary-button small" onClick={() => setPrimary(method.id)}>Tornar principal</button>}
        </div>)}
      </section>
      <section className="panel"><div className="section-kicker">NOVO MÉTODO</div><h2>Adicionar conta</h2><p className="muted">Cadastre MB WAY ou IBAN para usar nas solicitações de saque.</p>
        <label className="field-label">Tipo<select value={type} onChange={(e) => setType(e.target.value as "MBWAY" | "IBAN")}><option value="MBWAY">MB WAY</option><option value="IBAN">IBAN</option></select></label>
        <label className="field-label">Número / chave<input value={value} onChange={(e) => setValue(e.target.value)} placeholder={type === "MBWAY" ? "+351 900 000 000" : "PT50 0000 0000 0000 0000 0000 0"} /></label>
        <button className="primary-button" onClick={add}><Plus size={16} />Adicionar método</button>
      </section>
    </div>
  </div>;
}