import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/app/saques")({
  component: () => (
    <div>
      <h1>Solicitar saque</h1>
      <p>Solicite a transferência do seu saldo disponível.</p>
    </div>
  ),
});
