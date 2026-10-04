import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
Deno.serve(async(req)=>{
  if(req.method!=="POST")return new Response("Method Not Allowed",{status:405});
  const expected=Deno.env.get("JAGUAPAY_BOOTSTRAP_SECRET");if(!expected||req.headers.get("x-bootstrap-secret")!==expected)return new Response("Forbidden",{status:403});
  try{
    const {email}=await req.json();const normalized=String(email||"").trim().toLowerCase();if(!normalized)return new Response("E-mail obrigatório",{status:400});
    const url=Deno.env.get("SUPABASE_URL")!,key=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;const admin=createClient(url,key);
    const {data,error}=await admin.rpc("bootstrap_superadmin",{p_email:normalized});if(error)throw error;
    return new Response(JSON.stringify({ok:true}),{headers:{"Content-Type":"application/json"}});
  }catch(error){return new Response(JSON.stringify({error:error instanceof Error?error.message:"Falha ao provisionar superadministrador."}),{status:400,headers:{"Content-Type":"application/json"}})}
});