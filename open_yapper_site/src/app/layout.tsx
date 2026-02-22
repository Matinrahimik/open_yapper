import type { Metadata } from "next";
import { Anton, Space_Grotesk } from "next/font/google";
import { SmoothScroll } from "@/components/SmoothScroll";
import { Analytics } from "@/components/Analytics";
import "./globals.css";

const anton = Anton({
  weight: "400",
  variable: "--font-anton",
  subsets: ["latin"],
});

const spaceGrotesk = Space_Grotesk({
  weight: ["400", "500", "600", "700"],
  variable: "--font-space-grotesk",
  subsets: ["latin"],
});

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "https://openyapper.com";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  icons: {
    icon: "/logo.png",
    apple: "/logo.png",
  },
  title: "Open Yapper - Stop Typing, Start Talking",
  description:
    "The GEN Z voice dictation app. Open-source Wispr Flow alternative—ramble naturally, AI cleans the mess, no cap. Removes filler words, refines your text, paste anywhere.",
  keywords: [
    "voice dictation",
    "speech to text",
    "Wispr Flow alternative",
    "GEN Z app",
    "AI transcription",
    "open source",
  ],
  openGraph: {
    title: "Open Yapper - Stop Typing, Start Talking",
    description:
      "The GEN Z voice dictation app. Open-source Wispr Flow alternative—ramble naturally, AI cleans the mess. Stop typing, start talking.",
    images: ["/og-image.png"],
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Open Yapper - Stop Typing, Start Talking",
    description:
      "The GEN Z voice dictation app. Open-source Wispr Flow alternative—ramble naturally, AI cleans the mess. Stop typing, start talking.",
    images: ["/og-image.png"],
  },
  robots: {
    index: true,
    follow: true,
  },
};

export const viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${anton.variable} ${spaceGrotesk.variable} antialiased`}
      >
        <Analytics />
        <SmoothScroll>{children}</SmoothScroll>
      </body>
    </html>
  );
}
