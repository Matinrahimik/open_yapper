import type { Metadata } from "next";
import { Anton, Space_Grotesk } from "next/font/google";
import { SmoothScroll } from "@/components/SmoothScroll";
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
  title: "Open Yapper - Stop Typing, Start Talking",
  description:
    "Voice dictation that removes filler words and refines your text. Ramble naturally, AI cleans the mess, paste anywhere.",
  openGraph: {
    title: "Open Yapper - Stop Typing, Start Talking",
    description:
      "Voice dictation that removes filler words and refines your text. Ramble naturally, AI cleans the mess, paste anywhere.",
    images: ["/og-image.png"],
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Open Yapper - Stop Typing, Start Talking",
    description:
      "Voice dictation that removes filler words and refines your text. Ramble naturally, AI cleans the mess, paste anywhere.",
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
        <SmoothScroll>{children}</SmoothScroll>
      </body>
    </html>
  );
}
