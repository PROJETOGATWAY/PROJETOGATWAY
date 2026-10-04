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
      .subscribe((status)=>{if(status==="SUBSCRIBED")void load()});
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
      .subscribe((status)=>{if(status==="SUBSCRIBED")void load()});
    return()=>{mounted=false;void supabase.removeChannel(channel)};
  },[]);
  return{data,loading,error};
}

export type SellerLedgerEntry={id:string;kind:"payment"|"withdrawal";status:string;amount_eur:number;created_at:string;reference:string|null};

export function useSellerLedger(){
  const[data,setData]=useState<SellerLedgerEntry[]>([]);
  const[loading,setLoading]=useState(true);
  useEffect(()=>{
    const supabase=getSupabase();let mounted=true;
    const load=async()=>{
      const[{data:payments},{data:withdrawals}]=await Promise.all([
        supabase.from("payment_records").select("id,status,net_amount_eur,gross_amount_eur,reference,created_at").order("created_at",{ascending:false}).limit(20),
        supabase.from("withdrawals").select("id,status,amount_eur,created_at").order("created_at",{ascending:false}).limit(20)
      ]);
      if(!mounted)return;
      const entries=[
        ...(payments||[]).map(p=>({id:p.id,kind:"payment" as const,status:p.status,amount_eur:Number(p.net_amount_eur||0),created_at:p.created_at,reference:p.reference||null})),
        ...(withdrawals||[]).map(w=>({id:w.id,kind:"withdrawal" as const,status:w.status,amount_eur:-Number(w.amount_eur||0),created_at:w.created_at,reference:null}))
      ].sort((a,b)=>new Date(b.created_at).getTime()-new Date(a.created_at).getTime()).slice(0,20);
      setData(entries);setLoading(false);
    };
    void load();
    const channel=supabase.channel("seller-ledger-live")
      .on("postgres_changes",{event:"*",schema:"public",table:"payment_records"},()=>{void load()})
      .on("postgres_changes",{event:"*",schema:"public",table:"withdrawals"},()=>{void load()})
      .subscribe((status)=>{if(status==="SUBSCRIBED")void load()});
    return()=>{mounted=false;void supabase.removeChannel(channel)};
  },[]);
  return{data,loading};
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
export type PaymentRecord={
  id:string;payment_code:string;seller_id:string;gross_amount_eur:number;currency:"EUR";payment_method:"mbway"|"iban";fee_percent_snapshot:number;fee_amount_eur:number;net_amount_eur:number;status:"pending"|"under_review"|"approved"|"rejected"|"estornado";reference:string|null;order_id:string|null;notes:string|null;mbway_phone_snapshot:string|null;central_iban_snapshot:string|null;proof_path:string|null;proof_mime_type:string|null;proof_size_bytes:number|null;admin_notes:string|null;decision_reason:string|null;decided_by:string|null;receipt_id:string|null;created_at:string;submitted_at:string;approved_at:string|null;updated_at:string;
};
export type CentralReceipt={id:string;receipt_reference:string;received_at:string;amount_eur:number;payment_method:"mbway"|"iban";observation:string|null;seller_id:string|null;payment_id:string|null;created_by:string;created_at:string};
export type AdminNote={id:string;payment_id:string;admin_id:string;note:string;created_at:string};

export async function createPaymentSubmission(input:{gross_amount_eur:number;payment_method:"mbway"|"iban";reference:string;order_id:string;notes:string;idempotency_key:string}){
  const{data,error}=await getSupabase().rpc("create_payment_submission",{
    p_gross_amount_eur:input.gross_amount_eur,p_payment_method:input.payment_method,p_reference:input.reference||null,p_order_id:input.order_id||null,p_notes:input.notes||null,p_idempotency_key:input.idempotency_key
  });
  if(error)throw error;return data as PaymentRecord;
}
export async function finalizePaymentSubmission(paymentId:string,path:string,mime:string,size:number){
  const{data,error}=await getSupabase().rpc("finalize_payment_submission",{p_payment_id:paymentId,p_proof_path:path,p_proof_mime_type:mime,p_proof_size_bytes:size});
  if(error)throw error;return data as PaymentRecord;
}
export async function cleanupFailedPaymentSubmission(paymentId:string){await getSupabase().rpc("cleanup_failed_payment_submission",{p_payment_id:paymentId});}
export async function listSellerPayments(limit=50){
  const{data,error}=await getSupabase().from("payment_records").select("*").order("created_at",{ascending:false}).limit(limit);
  if(error)throw error;return (data||[]) as PaymentRecord[];
}
export async function listAdminPayments(status?:string){
  let q=getSupabase().from("payment_records").select("*").order("created_at",{ascending:false}).limit(100);
  if(status&&status!=="all")q=q.eq("status",status);
  const{data,error}=await q;if(error)throw error;return(data||[]) as PaymentRecord[];
}
export async function listCentralReceipts(){
  const{data,error}=await getSupabase().from("central_receipts").select("*").order("received_at",{ascending:false}).limit(100);
  if(error)throw error;return(data||[]) as CentralReceipt[];
}
export async function listPaymentNotes(paymentId:string){
  const{data,error}=await getSupabase().from("payment_admin_notes").select("*").eq("payment_id",paymentId).order("created_at",{ascending:false});
  if(error)throw error;return(data||[]) as AdminNote[];
}
export async function adminAddPaymentNote(paymentId:string,note:string){const{data,error}=await getSupabase().rpc("admin_add_payment_note",{p_payment_id:paymentId,p_note:note});if(error)throw error;return data as AdminNote}
export async function adminRejectPayment(paymentId:string,reason:string){const{data,error}=await getSupabase().rpc("admin_reject_payment",{p_payment_id:paymentId,p_reason:reason});if(error)throw error;return data as PaymentRecord}
export async function adminEscalatePayment(paymentId:string,reason:string){const{data,error}=await getSupabase().rpc("admin_escalate_payment",{p_payment_id:paymentId,p_reason:reason});if(error)throw error;return data as PaymentRecord}
export async function adminReversePayment(paymentId:string,reason:string){const{data,error}=await getSupabase().rpc("admin_reverse_payment",{p_payment_id:paymentId,p_reason:reason});if(error)throw error;return data as PaymentRecord}
export async function adminApprovePayment(paymentId:string,input:{receiptId?:string;reference?:string;receivedAt?:string;amount?:number;method?:string;observation?:string}){
  const{data,error}=await getSupabase().rpc("admin_approve_payment",{
    p_payment_id:paymentId,p_receipt_id:input.receiptId||null,p_new_receipt_reference:input.reference||null,p_new_receipt_at:input.receivedAt||null,p_new_receipt_amount_eur:input.amount??null,p_new_receipt_method:input.method||null,p_new_receipt_observation:input.observation||null
  });if(error)throw error;return data as PaymentRecord;
}
export async function openPaymentProof(path:string){const{data,error}=await getSupabase().storage.from("payment-proofs").createSignedUrl(path,300);if(error)throw error;window.open(data.signedUrl,"_blank","noopener,noreferrer")}
