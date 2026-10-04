import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/app/pagamentos")({
  component: () => (
    <div>
      <h1>Lançar pagamento</h1>
      <p>Crie um novo pagamento para seus clientes.</p>
    </div>
  ),
});
