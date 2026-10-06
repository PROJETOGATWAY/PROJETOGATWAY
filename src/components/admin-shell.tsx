import { Link, useLocation } from "@tanstack/react-router";
import { ClipboardList, LayoutDashboard, Settings, ShieldCheck, Users, UserCog, WalletCards, SearchCheck, Landmark, FileClock, Menu, X } from "lucide-react";
import { useState, type ReactNode } from "react";
import { NotificationsBell } from "./notifications";
import { useAuth, adminLevelLabel } from "../lib/auth";
import brandLogo from "../assets/aron-pay-logo.png.asset.json";

const items = [["/admin", "Resumo", ShieldCheck], ["/admin/vendedores", "Vendedores", Users], ["/admin/administradores", "Administradores", UserCog], ["/admin/pagamentos", "Pagamentos para análise", SearchCheck], ["/admin/conciliacao", "Conciliação", Landmark], ["/admin/saques", "Saques", WalletCards], ["/admin/configuracoes", "Configurações", Settings], ["/admin/auditoria", "Auditoria", FileClock], ["/admin/suporte", "Suporte", ClipboardList]] as const;

export function AdminShell({ children }: { children: ReactNode }) {
  const location = useLocation();
  const { profile } = useAuth();
  const [open, setOpen] = useState(false);
  const visibleItems = profile?.admin_level === "superadmin"
    ? items
    : profile?.admin_level === "contador"
      ? [["/admin/painel", "Painel", LayoutDashboard], ...items.filter(([to]) => to === "/admin/pagamentos" || to === "/admin/saques")] as const
      : items.filter(([to]) => to !== "/admin/administradores" && to !== "/admin/configuracoes");

  return <div className="jaguar-app">
    <aside className={"jaguar-sidebar " + (open ? "is-open" : "")}>
      <div className="brand-block"><img className="brand-logo brand-logo-jaguar" src={brandLogo.url} alt="Logo ARON PAY" width={40} height={40}/><div className="brand-name">ARON PAY</div><button className="icon-button mobile-only" type="button" aria-label="Fechar menu" onClick={() => setOpen(false)}><X size={18} /></button></div>
      <div className="sidebar-status"><span>ÁREA ADMINISTRATIVA</span><strong>{adminLevelLabel(profile?.admin_level || "standard")}</strong></div>
      <nav className="sidebar-nav" aria-label="Administração"><div className="nav-label">OPERAÇÃO</div>
        {visibleItems.map(([to, label, Icon]) => <Link key={to} to={to} onClick={() => setOpen(false)} className={"nav-item " + ((to === "/admin" ? location.pathname === "/admin" : location.pathname.startsWith(to)) ? "active" : "")}><Icon size={18} /><span>{label}</span></Link>)}
      </nav>
    </aside>
    {open && <button className="sidebar-overlay mobile-only" type="button" aria-label="Fechar menu" onClick={() => setOpen(false)} />}
    <main className="jaguar-main">
      <header className="topbar"><button className="icon-button mobile-only" type="button" aria-label="Abrir menu" onClick={() => setOpen(true)}><Menu size={19} /></button><div className="topbar-system"><span>AMBIENTE</span><strong>ARON PAY ADMIN</strong></div><div className="topbar-user"><NotificationsBell /><strong>{profile?.full_name || "Administrador"} · {adminLevelLabel(profile?.admin_level || "standard")}</strong></div></header>
      <div className="content-area">{children}</div>
    </main>
  </div>;
}