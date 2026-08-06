"use client";

import { useEffect, useState } from "react";

type HealthResponse = {
  status: string;
  service: string;
  time: string;
};

export default function Home() {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

    fetch(`${apiUrl}/health`)
      .then((res) => {
        if (!res.ok) throw new Error(`Backend responded ${res.status}`);
        return res.json();
      })
      .then(setHealth)
      .catch((err) => setError(err.message));
  }, []);

  return (
    <main className="min-h-screen flex flex-col items-center justify-center gap-6 p-8">
      <div className="text-center">
        <h1 className="text-3xl font-semibold tracking-tight">
          AutoParts Supply Chain Intelligence Platform
        </h1>
        <p className="mt-2 text-slate-500">
          Supplier risk scoring · RFQ extraction · demand forecasting · GenAI copilot
        </p>
      </div>

      <div className="rounded-lg border border-slate-200 bg-white px-6 py-4 shadow-sm">
        <p className="text-sm font-medium text-slate-600">Backend connection</p>
        {error && (
          <p className="mt-1 text-sm text-red-600">
            Could not reach backend: {error}
          </p>
        )}
        {!error && !health && (
          <p className="mt-1 text-sm text-slate-400">Checking...</p>
        )}
        {health && (
          <p className="mt-1 text-sm text-emerald-600">
            {health.service} — {health.status} (as of{" "}
            {new Date(health.time).toLocaleTimeString()})
          </p>
        )}
      </div>

      <p className="text-xs text-slate-400">
        Dashboard modules (suppliers, inventory, RFQs, forecasts, copilot) are
        built out step by step — see the roadmap in the project README.
      </p>
    </main>
  );
}
