/* eslint-disable */
// @ts-nocheck
import{Route as rootRouteImport}from'./routes/__root'
import{Route as IndexRouteImport}from'./routes/index'
import{Route as AdminRouteImport}from'./routes/admin'
import{Route as AppRouteImport}from'./routes/app'
import{Route as AtualizarSenhaRouteImport}from'./routes/atualizar-senha'
import{Route as CadastroRouteImport}from'./routes/cadastro'
import{Route as LoginRouteImport}from'./routes/login'
import{Route as RecuperarSenhaRouteImport}from'./routes/recuperar-senha'
const IndexRoute=IndexRouteImport.update({id:'/',path:'/',getParentRoute:()=>rootRouteImport}as any)
const AdminRoute=AdminRouteImport.update({id:'/admin',path:'/admin',getParentRoute:()=>rootRouteImport}as any)
const AppRoute=AppRouteImport.update({id:'/app',path:'/app',getParentRoute:()=>rootRouteImport}as any)
const AtualizarSenhaRoute=AtualizarSenhaRouteImport.update({id:'/atualizar-senha',path:'/atualizar-senha',getParentRoute:()=>rootRouteImport}as any)
const CadastroRoute=CadastroRouteImport.update({id:'/cadastro',path:'/cadastro',getParentRoute:()=>rootRouteImport}as any)
const LoginRoute=LoginRouteImport.update({id:'/login',path:'/login',getParentRoute:()=>rootRouteImport}as any)
const RecuperarSenhaRoute=RecuperarSenhaRouteImport.update({id:'/recuperar-senha',path:'/recuperar-senha',getParentRoute:()=>rootRouteImport}as any)
export interface FileRoutesByFullPath{'/':typeof IndexRoute;'/admin':typeof AdminRoute;'/app':typeof AppRoute;'/atualizar-senha':typeof AtualizarSenhaRoute;'/cadastro':typeof CadastroRoute;'/login':typeof LoginRoute;'/recuperar-senha':typeof RecuperarSenhaRoute}
export interface FileRoutesByTo extends FileRoutesByFullPath{}
export interface FileRoutesById{'__root__':typeof rootRouteImport;'/':typeof IndexRoute;'/admin':typeof AdminRoute;'/app':typeof AppRoute;'/atualizar-senha':typeof AtualizarSenhaRoute;'/cadastro':typeof CadastroRoute;'/login':typeof LoginRoute;'/recuperar-senha':typeof RecuperarSenhaRoute}
export interface FileRouteTypes{fileRoutesByFullPath:FileRoutesByFullPath;fullPaths:keyof FileRoutesByFullPath;fileRoutesByTo:FileRoutesByTo;to:keyof FileRoutesByTo;id:keyof FileRoutesById;fileRoutesById:FileRoutesById}
export interface RootRouteChildren{IndexRoute:typeof IndexRoute;AdminRoute:typeof AdminRoute;AppRoute:typeof AppRoute;AtualizarSenhaRoute:typeof AtualizarSenhaRoute;CadastroRoute:typeof CadastroRoute;LoginRoute:typeof LoginRoute;RecuperarSenhaRoute:typeof RecuperarSenhaRoute}
declare module '@tanstack/react-router'{interface FileRoutesByPath{
'/':{id:'/';path:'/';fullPath:'/';preLoaderRoute:typeof IndexRouteImport;parentRoute:typeof rootRouteImport}
'/admin':{id:'/admin';path:'/admin';fullPath:'/admin';preLoaderRoute:typeof AdminRouteImport;parentRoute:typeof rootRouteImport}
'/app':{id:'/app';path:'/app';fullPath:'/app';preLoaderRoute:typeof AppRouteImport;parentRoute:typeof rootRouteImport}
'/atualizar-senha':{id:'/atualizar-senha';path:'/atualizar-senha';fullPath:'/atualizar-senha';preLoaderRoute:typeof AtualizarSenhaRouteImport;parentRoute:typeof rootRouteImport}
'/cadastro':{id:'/cadastro';path:'/cadastro';fullPath:'/cadastro';preLoaderRoute:typeof CadastroRouteImport;parentRoute:typeof rootRouteImport}
'/login':{id:'/login';path:'/login';fullPath:'/login';preLoaderRoute:typeof LoginRouteImport;parentRoute:typeof rootRouteImport}
'/recuperar-senha':{id:'/recuperar-senha';path:'/recuperar-senha';fullPath:'/recuperar-senha';preLoaderRoute:typeof RecuperarSenhaRouteImport;parentRoute:typeof rootRouteImport}
}}
const rootRouteChildren={IndexRoute,AdminRoute,AppRoute,AtualizarSenhaRoute,CadastroRoute,LoginRoute,RecuperarSenhaRoute}
export const routeTree=rootRouteImport._addFileChildren(rootRouteChildren)._addFileTypes<FileRouteTypes>()
import type{getRouter}from'./router.tsx';import type{startInstance}from'./start.ts'
declare module '@tanstack/react-start'{interface Register{ssr:true;router:Awaited<ReturnType<typeof getRouter>>;config:Awaited<ReturnType<typeof startInstance.getOptions>>}}
