import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ASCIP — AutoParts Supply Chain Intelligence Platform",
  description:
    "Supplier risk scoring, RFQ extraction, demand forecasting, and a GenAI copilot for automotive procurement.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
