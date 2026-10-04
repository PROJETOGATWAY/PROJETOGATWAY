import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/app/")({
  component: () => (
    <div>
      <h1>Visão geral</h1>
      <p>Resumo da sua conta Jaguar Pay.</p>
    </div>
  ),
});
