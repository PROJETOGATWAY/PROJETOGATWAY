import { useEffect,useState,type FormEvent,type ReactNode } from "react";
import { createFileRoute,Link,useNavigate } from "@tanstack/react-router";
import { ArrowRight,LockKeyhole,Mail } from "lucide-react";
import { useAuth } from "../lib/auth";
import { getSupabase } from "../lib/supabase";
import jaguarIdentity from "../assets/jaguar-identity.webp";

export const Route=createFileRoute("/login")({head:()=>({meta:[{title:'Entrar — ARON PAY'},{name:"description",content:'Entre na sua conta ARON PAY com segurança.'},{property:"og:title",content:'Entrar — ARON PAY'},{property:"og:description",content:'Entre na sua conta ARON PAY com segurança.'},{property:"og:type",content:"website"},{name:"twitter:card",content:"summary"}]}),component:LoginPage});

export function AuthLayout({eyebrow,title,subtitle,children}:{eyebrow?:string;title:string;subtitle?:string;children:ReactNode}){
  return <div className="auth-page">
    <img className="auth-bg" src={authBg} alt="" aria-hidden="true"/>
    <div className="auth-shade" aria-hidden="true"/>
    <div className="auth-stage">
      <section className="auth-hero" aria-hidden="true">
        <img className="auth-hero-jaguar" src={jaguarHero} alt="" width={1024} height={640}/>
        <div className="auth-wordmark"><span>ARON</span><strong>PAY</strong></div>
        <div className="auth-hero-copy">GATEWAY FOCADO EM PAGAMENTO EUROPEU LOCAL</div>
        <div className="auth-hero-line"/>
      </section>
      <div className="auth-card">
        {eyebrow?<span className="eyebrow">{eyebrow}</span>:null}
        <h1>{title}</h1>
        {subtitle?<p className="auth-subtitle">{subtitle}</p>:null}
        {children}
      </div>
      <div className="auth-footer">SEJA PREDATOR.<br/>ESTEJA ENTRE A ELITE.</div>
    </div>
  </div>;
}

function LoginPage(){
  const{user,profile}=useAuth();
  const navigate=useNavigate();
  const[email,setEmail]=useState("");
  const[password,setPassword]=useState("");
  const[error,setError]=useState("");
  const[busy,setBusy]=useState(false);
  useEffect(()=>{
    if(!user||!profile||profile.status!=="active")return;
    if(profile.role==="admin")void navigate({to:profile.admin_level==="contador"?"/app":"/admin",replace:true});
    else void navigate({to:"/app",replace:true});
  },[user,profile,navigate]);
  const submit=async(e:FormEvent)=>{
    e.preventDefault();
    setError("");
    setBusy(true);
    const{error}=await getSupabase().auth.signInWithPassword({email,password});
    setBusy(false);
    if(error)setError("E-mail ou senha inválidos.");
  };
  return <AuthLayout title="Acesse sua conta">
    <form className="auth-form" onSubmit={submit}>
      <label>E-mail
        <div className="input-with-icon"><Mail size={16}/><input required type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="Seu e-mail"/></div>
      </label>
      <label>Senha
        <div className="input-with-icon"><LockKeyhole size={16}/><input required type="password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="Sua senha"/></div>
      </label>
      {error&&<div className="form-error">{error}</div>}
      <button className="primary-button" disabled={busy}>{busy?"Entrando…":"Entrar"}<ArrowRight size={16}/></button>
      <div className="auth-links">
        <Link to="/recuperar-senha">Esqueci minha senha</Link>
        <Link to="/cadastro">Criar conta</Link>
      </div>
    </form>
  </AuthLayout>;
}
