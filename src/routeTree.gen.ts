/* eslint-disable */
// @ts-nocheck
import{Route as rootRouteImport}from'./routes/__root'
import{Route as IndexRouteImport}from'./routes/index'
import{Route as AdminRouteImport}from'./routes/admin'
import{Route as AdminIndexRouteImport}from'./routes/admin/index'
import{Route as AdminVendedoresRouteImport}from'./routes/admin/vendedores'
import{Route as AdminAdministradoresRouteImport}from'./routes/admin/administradores'
import{Route as AdminPagamentosRouteImport}from'./routes/admin/pagamentos'
import{Route as AdminConciliacaoRouteImport}from'./routes/admin/conciliacao'
import{Route as AdminSaquesRouteImport}from'./routes/admin/saques'
import{Route as AdminConfiguracoesRouteImport}from'./routes/admin/configuracoes'
import{Route as AdminAuditoriaRouteImport}from'./routes/admin/auditoria'
import{Route as AppRouteImport}from'./routes/app'
import{Route as AtualizarSenhaRouteImport}from'./routes/atualizar-senha'
import{Route as CadastroRouteImport}from'./routes/cadastro'
import{Route as LoginRouteImport}from'./routes/login'
import{Route as RecuperarSenhaRouteImport}from'./routes/recuperar-senha'
import{Route as AppIndexRouteImport}from'./routes/app/index'
import{Route as AppMetodosRouteImport}from'./routes/app/metodos'
import{Route as AppPagamentosRouteImport}from'./routes/app/pagamentos'
import{Route as AppPerfilRouteImport}from'./routes/app/perfil'
import{Route as AppSaquesRouteImport}from'./routes/app/saques'
import{Route as AppSuporteRouteImport}from'./routes/app/suporte'
const IndexRoute=IndexRouteImport.update({id:'/',path:'/',getParentRoute:()=>rootRouteImport}as any)
const AdminRoute=AdminRouteImport.update({id:'/admin',path:'/admin',getParentRoute:()=>rootRouteImport}as any)
const AdminIndexRoute=AdminIndexRouteImport.update({id:'/',path:'/',getParentRoute:()=>AdminRoute}as any)
const AdminVendedoresRoute=AdminVendedoresRouteImport.update({id:'/vendedores',path:'/vendedores',getParentRoute:()=>AdminRoute}as any)
const AdminAdministradoresRoute=AdminAdministradoresRouteImport.update({id:'/administradores',path:'/administradores',getParentRoute:()=>AdminRoute}as any)
const AdminPagamentosRoute=AdminPagamentosRouteImport.update({id:'/pagamentos',path:'/pagamentos',getParentRoute:()=>AdminRoute}as any)
const AdminConciliacaoRoute=AdminConciliacaoRouteImport.update({id:'/conciliacao',path:'/conciliacao',getParentRoute:()=>AdminRoute}as any)
const AdminSaquesRoute=AdminSaquesRouteImport.update({id:'/saques',path:'/saques',getParentRoute:()=>AdminRoute}as any)
const AdminConfiguracoesRoute=AdminConfiguracoesRouteImport.update({id:'/configuracoes',path:'/configuracoes',getParentRoute:()=>AdminRoute}as any)
const AdminAuditoriaRoute=AdminAuditoriaRouteImport.update({id:'/auditoria',path:'/auditoria',getParentRoute:()=>AdminRoute}as any)
const AppRoute=AppRouteImport.update({id:'/app',path:'/app',getParentRoute:()=>rootRouteImport}as any)
const AppIndexRoute=AppIndexRouteImport.update({id:'/',path:'/',getParentRoute:()=>AppRoute}as any)
const AppMetodosRoute=AppMetodosRouteImport.update({id:'/metodos',path:'/metodos',getParentRoute:()=>AppRoute}as any)
const AppPagamentosRoute=AppPagamentosRouteImport.update({id:'/pagamentos',path:'/pagamentos',getParentRoute:()=>AppRoute}as any)
const AppPerfilRoute=AppPerfilRouteImport.update({id:'/perfil',path:'/perfil',getParentRoute:()=>AppRoute}as any)
const AppSaquesRoute=AppSaquesRouteImport.update({id:'/saques',path:'/saques',getParentRoute:()=>AppRoute}as any)
const AppSuporteRoute=AppSuporteRouteImport.update({id:'/suporte',path:'/suporte',getParentRoute:()=>AppRoute}as any)
const AtualizarSenhaRoute=AtualizarSenhaRouteImport.update({id:'/atualizar-senha',path:'/atualizar-senha',getParentRoute:()=>rootRouteImport}as any)
const CadastroRoute=CadastroRouteImport.update({id:'/cadastro',path:'/cadastro',getParentRoute:()=>rootRouteImport}as any)
const LoginRoute=LoginRouteImport.update({id:'/login',path:'/login',getParentRoute:()=>rootRouteImport}as any)
const RecuperarSenhaRoute=RecuperarSenhaRouteImport.update({id:'/recuperar-senha',path:'/recuperar-senha',getParentRoute:()=>rootRouteImport}as any)
const AdminChildren={AdminIndexRoute,AdminVendedoresRoute,AdminAdministradoresRoute,AdminPagamentosRoute,AdminConciliacaoRoute,AdminSaquesRoute,AdminConfiguracoesRoute,AdminAuditoriaRoute}
const AppChildren={AppIndexRoute,AppMetodosRoute,AppPagamentosRoute,AppPerfilRoute,AppSaquesRoute,AppSuporteRoute}
const AdminRouteWithChildren=AdminRoute._addFileChildren(AdminChildren)
const AppRouteWithChildren=AppRoute._addFileChildren(AppChildren)
export const routeTree=rootRouteImport._addFileChildren({IndexRoute,AdminRoute:AdminRouteWithChildren,AppRoute:AppRouteWithChildren,AtualizarSenhaRoute,CadastroRoute,LoginRoute,RecuperarSenhaRoute})._addFileTypes<any>()
