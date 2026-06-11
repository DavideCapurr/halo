import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Halo — Campagne",
  description: "Sostieni una campagna Halo: tante piccole donazioni verso un obiettivo.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="it">
      <body>{children}</body>
    </html>
  );
}
