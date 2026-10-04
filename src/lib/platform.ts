import{useEffect,useState}from"react";import{getSupabase}from"./supabase";

export type PlatformSettings={
  id:number;
  mbway_phone:string|null;
  central_iban:string|null;
  platform_fee_percent:number;
  minimum_withdrawal_eur:number;
  withdrawal_fixed_fee_eur:number;
  withdrawals_paused:boolean;
  initialized_at:string|null;
  updated_at:string;
  updated_by:string|null;
};

export type SellerDashboard={
  available_balance_eur:number;
  pending_balance_eur:number;
  approved_volume_eur:number;
  at_risk_eur:number;
  reserved_withdrawals_eur:number;
};

const EMPTY_DASHBOARD:SellerDashboard={available_balance_eur:0,pending_balance_eur:0,approved_volume_eur:0,at_risk_eur:0,reserved_withdrawals_eur:0};

export function usePlatformSettings(){
  const[settings,setSettings]=useState<PlatformSettings|null>(null);
  const[loading,setLoading]=useState(true);
  const[error,setError]=useState<string|null>(null);
  useEffect(()=>{
    const supabase=getSupabase();
    let mounted=true;
    const load=async()=>{
      const{data,error}=await supabase.from("platform_settings").select("*").eq("id",1).maybeSingle();
      if(!mounted)return;
      if(error){setError("Não foi possível carregar as configurações da operação.");setLoading(false);return}
      setSettings(data as PlatformSettings|null);
      setError(null);
      setLoading(false);
    };
    void load();
    const channel=supabase.channel("platform-settings-live")
      .on("postgres_changes",{event:"*",schema:"public",table:"platform_settings"},()=>{void load()})
      .subscribe();
    const onVisible=()=>{if(document.visibilityState==="visible")void load()};
    window.addEventListener("visibilitychange",onVisible);
    return()=>{mounted=false;window.removeEventListener("visibilitychange",onVisible);void supabase.removeChannel(channel)};
  },[]);
  return{settings,loading,error,configured:Boolean(settings?.initialized_at)};
}

export async function savePlatformSettings(input:Omit<PlatformSettings,"id"|"initialized_at"|"updated_at"|"updated_by">){
  const{data,error}=await getSupabase().rpc("save_platform_settings",{
    p_mbway_phone:input.mbway_phone,
    p_central_iban:input.central_iban,
    p_platform_fee_percent:input.platform_fee_percent,
    p_minimum_withdrawal_eur:input.minimum_withdrawal_eur,
    p_withdrawal_fixed_fee_eur:input.withdrawal_fixed_fee_eur,
    p_withdrawals_paused:input.withdrawals_paused,
  });
  if(error)throw error;
  return data as PlatformSettings;
}

export function useSellerDashboard(){
  const[data,setData]=useState<SellerDashboard>(EMPTY_DASHBOARD);
  const[loading,setLoading]=useState(true);
  const[error,setError]=useState<string|null>(null);
  useEffect(()=>{
    const supabase=getSupabase();
    let mounted=true;
    const load=async()=>{
      const{data,error}=await supabase.rpc("get_seller_dashboard");
      if(!mounted)return;
      if(error){setError("Não foi possível carregar o resumo financeiro.");setLoading(false);return}
      const row=Array.isArray(data)?data[0]:data;
      setData(row?{
        available_balance_eur:Number(row.available_balance_eur||0),
        pending_balance_eur:Number(row.pending_balance_eur||0),
        approved_volume_eur:Number(row.approved_volume_eur||0),
        at_risk_eur:Number(row.at_risk_eur||0),
        reserved_withdrawals_eur:Number(row.reserved_withdrawals_eur||0),
      }:EMPTY_DASHBOARD);
      setError(null);setLoading(false);
    };
    void load();
    const channel=supabase.channel("seller-financial-live")
      .on("postgres_changes",{event:"*",schema:"public",table:"payment_records"},()=>{void load()})
      .on("postgres_changes",{event:"*",schema:"public",table:"withdrawals"},()=>{void load()})
      .subscribe();
    return()=>{mounted=false;void supabase.removeChannel(channel)};
  },[]);
  return{data,loading,error};
}

export function formatEur(value:number){
  return new Intl.NumberFormat("pt-PT",{style:"currency",currency:"EUR",minimumFractionDigits:2}).format(value||0);
}

export function copyText(text:string){
  if(navigator.clipboard?.writeText)return navigator.clipboard.writeText(text);
  const area=document.createElement("textarea");area.value=text;area.style.position="fixed";area.style.opacity="0";document.body.appendChild(area);area.select();document.execCommand("copy");area.remove();return Promise.resolve();
}

export function whatsappInstructions(settings:PlatformSettings){
  const lines=["Dados para pagamento — JaguaPay"];
  if(settings.mbway_phone)lines.push(`MB WAY: ${settings.mbway_phone}`);
  if(settings.central_iban)lines.push(`IBAN: ${settings.central_iban}`);
  return lines.join("\n");
}