import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/app/metodos")({
  component: () => (
    <div>
      <h1>Métodos de saque</h1>
      <p>Gerencie suas contas e chaves para recebimento.</p>
    </div>
  ),
});
