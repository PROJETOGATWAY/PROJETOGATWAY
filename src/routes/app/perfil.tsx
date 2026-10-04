import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/app/perfil")({
  component: () => (
    <div>
      <h1>Perfil</h1>
      <p>Dados da sua conta de vendedor.</p>
    </div>
  ),
});
