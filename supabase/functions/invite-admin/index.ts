import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type"};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", {headers:cors});
  try {
    const supabaseUrl=Deno.env.get("SUPABASE_URL")!;
    const serviceKey=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const authHeader=req.headers.get("Authorization");
    if(!authHeader) throw new Error("Não autenticado");
    const adminClient=createClient(supabaseUrl,serviceKey,{global:{headers:{Authorization:authHeader}}});
    const {data:{user:actor},error:actorError}=await adminClient.auth.getUser();
    if(actorError||!actor) throw new Error("Não autenticado");
    const {data:actorProfile,error:profileError}=await adminClient.from("profiles").select("id,role,status,admin_level").eq("id",actor.id).single();
    if(profileError||actorProfile?.role!=="admin"||actorProfile?.admin_level!=="superadmin"||actorProfile?.status!=="active")
      return new Response(JSON.stringify({error:"Somente o superadministrador pode convidar administradores."}),{status:403,headers:{...cors,"Content-Type":"application/json"}});
    const body=await req.json();
    const email=String(body.email||"").trim().toLowerCase();
    if(!email) throw new Error("E-mail obrigatório");
    const {data:invitationId,error:recordError}=await adminClient.rpc("invite_admin_record",{p_email:email});
    if(recordError) throw recordError;
    const {data,error:inviteError}=await adminClient.auth.admin.inviteUserByEmail(email,{redirectTo:new URL("/login",req.url).toString()});
    if(inviteError){
      await adminClient.from("admin_invitations").update({status:"revoked"}).eq("id",invitationId);
      throw inviteError;
    }
    await adminClient.from("profiles").update({role:"admin",admin_level:"standard",status:"active"}).eq("id",data.user.id);
    await adminClient.from("admin_invitations").update({status:"accepted",accepted_at:new Date().toISOString()}).eq("id",invitationId);
    return new Response(JSON.stringify({ok:true,invitationId}),{headers:{...cors,"Content-Type":"application/json"}});
  } catch(error) {
    return new Response(JSON.stringify({error:error instanceof Error?error.message:"Falha ao convidar administrador."}),{status:400,headers:{...cors,"Content-Type":"application/json"}});
  }
});
