import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/app/suporte")({
  component: () => (
    <div>
      <h1>Suporte</h1>
      <p>Fale com o suporte operacional da Jaguar Pay.</p>
    </div>
  ),
});
