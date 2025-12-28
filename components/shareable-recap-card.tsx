"use client";

import { MonthlyRecapData } from "@/app/actions/reading-recap";
import { forwardRef } from "react";

interface ShareableRecapCardProps {
  data: MonthlyRecapData;
  type?: "post" | "story";
}

export const ShareableRecapCard = forwardRef<HTMLDivElement, ShareableRecapCardProps>(
  ({ data }, ref) => {
    return (
      <div
        ref={ref}
        style={{
          position: "relative",
          overflow: "hidden",
          width: "1080px",
          height: "1920px",
          background: "linear-gradient(135deg, #0f2027 0%, #203a43 25%, #2c5364 50%, #0f2027 100%)",
          fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif",
        }}
      >
        {/* Decorative background elements - iPhone style */}
        <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
          {/* Large gradient orbs */}
          <div style={{ position: "absolute", top: "-10%", left: "-5%", width: "600px", height: "600px", background: "radial-gradient(circle, rgba(0, 122, 255, 0.4) 0%, transparent 70%)", borderRadius: "9999px", filter: "blur(80px)" }} />
          <div style={{ position: "absolute", bottom: "-10%", right: "-5%", width: "700px", height: "700px", background: "radial-gradient(circle, rgba(88, 86, 214, 0.3) 0%, transparent 70%)", borderRadius: "9999px", filter: "blur(80px)" }} />
          <div style={{ position: "absolute", top: "30%", right: "10%", width: "400px", height: "400px", background: "radial-gradient(circle, rgba(94, 92, 230, 0.25) 0%, transparent 70%)", borderRadius: "9999px", filter: "blur(60px)" }} />

          {/* Subtle particles */}
          {[...Array(20)].map((_, i) => (
            <div
              key={i}
              style={{
                position: "absolute",
                borderRadius: "9999px",
                background: "rgba(255,255,255,0.15)",
                width: Math.random() * 6 + 3 + "px",
                height: Math.random() * 6 + 3 + "px",
                left: Math.random() * 100 + "%",
                top: Math.random() * 100 + "%",
              }}
            />
          ))}
        </div>

        {/* Content */}
        <div style={{ position: "relative", zIndex: 10, minHeight: "100%", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "5rem 4rem" }}>
          {/* Header */}
          <div style={{ textAlign: "center", marginBottom: "3rem" }}>
            {/* <div style={{ marginBottom: "2rem", display: "inline-block", position: "relative" }}>
              <svg width="120" height="120" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ filter: "drop-shadow(0 0 40px rgba(255,255,255,0.6))" }}>
                <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20" />
              </svg>
            </div> */}
            <h1 style={{ fontSize: "3rem", fontWeight: 900, color: "white", marginBottom: "0.25rem", textShadow: "0 0 50px rgba(255,255,255,0.5), 0 8px 30px rgba(0,0,0,0.3)" }}>
              My Reading
            </h1>
            <h2 style={{ fontSize: "4rem", fontWeight: 900, color: "white", textShadow: "0 0 30px rgba(255,255,255,0.4), 0 6px 20px rgba(0,0,0,0.3)" }}>
              {data.month} {data.year}
            </h2>
          </div>

          {/* Stats Grid */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "2.5rem", width: "100%", maxWidth: "900px", marginBottom: "3rem" }}>
            {/* Books */}
            <div style={{ position: "relative" }}>
              <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, rgba(0, 122, 255, 0.3), rgba(88, 86, 214, 0.2))", borderRadius: "2rem", filter: "blur(20px)", transform: "scale(1.05)" }} />
              <div style={{ position: "relative", background: "linear-gradient(135deg, rgba(255,255,255,0.15), rgba(255,255,255,0.05))", backdropFilter: "blur(20px) saturate(180%)", borderRadius: "2rem", padding: "2rem 1.5rem", border: "1px solid rgba(255,255,255,0.25)", textAlign: "center", boxShadow: "0 8px 32px 0 rgba(0, 0, 0, 0.37)" }}>
                <div style={{ fontSize: "7rem", fontWeight: 700, color: "white", marginBottom: "0.2rem", textShadow: "0 4px 30px rgba(0, 122, 255, 0.6)", letterSpacing: "-0.02em" }}>
                  {data.booksFinished}
                </div>
                <p style={{ fontSize: "2.75rem", fontWeight: 600, color: "rgba(255,255,255,0.95)", letterSpacing: "0.02em" }}>
                  {data.booksFinished === 1 ? "Book" : "Books"}
                </p>
              </div>
            </div>

            {/* Pages */}
            <div style={{ position: "relative" }}>
              <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, rgba(88, 86, 214, 0.3), rgba(94, 92, 230, 0.2))", borderRadius: "2rem", filter: "blur(20px)", transform: "scale(1.05)" }} />
              <div style={{ position: "relative", background: "linear-gradient(135deg, rgba(255,255,255,0.15), rgba(255,255,255,0.05))", backdropFilter: "blur(20px) saturate(180%)", borderRadius: "2rem", padding: "2rem 1.5rem", border: "1px solid rgba(255,255,255,0.25)", textAlign: "center", boxShadow: "0 8px 32px 0 rgba(0, 0, 0, 0.37)" }}>
                <div style={{ fontSize: "7rem", fontWeight: 700, color: "white", marginBottom: "0.2rem", textShadow: "0 4px 30px rgba(88, 86, 214, 0.6)", letterSpacing: "-0.02em" }}>
                  {data.pagesRead.toLocaleString()}
                </div>
                <p style={{ fontSize: "2.75rem", fontWeight: 600, color: "rgba(255,255,255,0.95)", letterSpacing: "0.02em" }}>Pages</p>
              </div>
            </div>
          </div>

          {/* Additional Stats */}
          <div style={{ display: "flex", flexDirection: "column", gap: "1.75rem", width: "100%", maxWidth: "900px" }}>
            {/* Top Genre */}
            {data.topGenre && (
              <div style={{ position: "relative" }}>
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, rgba(0, 122, 255, 0.25), rgba(10, 132, 255, 0.15))", borderRadius: "1.5rem", filter: "blur(16px)" }} />
                <div style={{ position: "relative", background: "linear-gradient(135deg, rgba(255,255,255,0.12), rgba(255,255,255,0.04))", backdropFilter: "blur(16px) saturate(180%)", borderRadius: "1.5rem", padding: "2rem 2.5rem", border: "1px solid rgba(255,255,255,0.2)", display: "flex", alignItems: "center", gap: "2rem", boxShadow: "0 4px 24px 0 rgba(0, 0, 0, 0.25)" }}>
                  <svg width="72" height="72" viewBox="0 0 24 24" fill="none" stroke="#0a84ff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ filter: "drop-shadow(0 0 24px rgba(10, 132, 255, 0.8))", flexShrink: 0 }}>
                    <path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6" />
                    <path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18" />
                    <path d="M4 22h16" />
                    <path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22" />
                    <path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22" />
                    <path d="M18 2H6v7a6 6 0 0 0 12 0V2Z" />
                  </svg>
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: "2rem", color: "rgba(255,255,255,0.75)", fontWeight: 600, marginBottom: "0.5rem", letterSpacing: "0.01em" }}>Favorite Genre</p>
                    <p style={{ fontSize: "3.5rem", fontWeight: 700, color: "white", textShadow: "0 4px 20px rgba(10, 132, 255, 0.4)", letterSpacing: "-0.01em" }}>
                      {data.topGenre}
                    </p>
                  </div>
                </div>
              </div>
            )}

            {/* Top Rated Book */}
            {data.topRatedBook && (
              <div style={{ position: "relative" }}>
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, rgba(255, 159, 10, 0.3), rgba(255, 214, 10, 0.15))", borderRadius: "1.5rem", filter: "blur(16px)" }} />
                <div style={{ position: "relative", background: "linear-gradient(135deg, rgba(255,255,255,0.12), rgba(255,255,255,0.04))", backdropFilter: "blur(16px) saturate(180%)", borderRadius: "1.5rem", padding: "2rem 2.5rem", border: "1px solid rgba(255,255,255,0.2)", display: "flex", alignItems: "center", gap: "2rem", boxShadow: "0 4px 24px 0 rgba(0, 0, 0, 0.25)" }}>
                  <svg width="72" height="72" viewBox="0 0 24 24" fill="#ff9f0a" stroke="#ff9f0a" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ filter: "drop-shadow(0 0 24px rgba(255, 159, 10, 0.8))", flexShrink: 0 }}>
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                  </svg>
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: "2rem", color: "rgba(255,255,255,0.75)", fontWeight: 600, marginBottom: "0.5rem", letterSpacing: "0.01em" }}>Top Rated</p>
                    <p style={{ fontSize: "3.25rem", fontWeight: 700, color: "white", marginBottom: "0.5rem", textShadow: "0 4px 20px rgba(255, 159, 10, 0.4)", letterSpacing: "-0.01em" }}>
                      {data.topRatedBook.title}
                    </p>
                    <div style={{ display: "flex", alignItems: "center", gap: "1rem", flexWrap: "wrap" }}>
                      <p style={{ fontSize: "2rem", color: "rgba(255,255,255,0.85)", fontWeight: 500 }}>by {data.topRatedBook.authors}</p>
                      <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", background: "rgba(255,159,10,0.25)", padding: "0.75rem 1.25rem", borderRadius: "9999px", border: "1px solid rgba(255,159,10,0.3)" }}>
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="#ff9f0a" stroke="none">
                          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                        </svg>
                        <span style={{ fontSize: "2rem", fontWeight: 700, color: "white" }}>{data.topRatedBook.rating}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Fastest Book */}
            {data.fastestBook && (
              <div style={{ position: "relative" }}>
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg, rgba(48, 209, 88, 0.3), rgba(52, 199, 89, 0.15))", borderRadius: "1.5rem", filter: "blur(16px)" }} />
                <div style={{ position: "relative", background: "linear-gradient(135deg, rgba(255,255,255,0.12), rgba(255,255,255,0.04))", backdropFilter: "blur(16px) saturate(180%)", borderRadius: "1.5rem", padding: "2rem 2.5rem", border: "1px solid rgba(255,255,255,0.2)", display: "flex", alignItems: "center", gap: "2rem", boxShadow: "0 4px 24px 0 rgba(0, 0, 0, 0.25)" }}>
                  <svg width="72" height="72" viewBox="0 0 24 24" fill="#30d158" stroke="#30d158" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ filter: "drop-shadow(0 0 24px rgba(48, 209, 88, 0.8))", flexShrink: 0 }}>
                    <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
                  </svg>
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: "2rem", color: "rgba(255,255,255,0.75)", fontWeight: 600, marginBottom: "0.5rem", letterSpacing: "0.01em" }}>Fastest Read</p>
                    <p style={{ fontSize: "3.25rem", fontWeight: 700, color: "white", marginBottom: "0.5rem", textShadow: "0 4px 20px rgba(48, 209, 88, 0.4)", letterSpacing: "-0.01em" }}>
                      {data.fastestBook.title}
                    </p>
                    <p style={{ fontSize: "2.25rem", color: "rgba(255,255,255,0.85)", fontWeight: 600 }}>
                      {data.fastestBook.days} {data.fastestBook.days === 1 ? "day" : "days"}
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Footer */}
          <div style={{ marginTop: "3rem", textAlign: "center" }}>
            <p style={{ fontSize: "2.25rem", color: "rgba(255,255,255,0.5)", fontWeight: 500, display: "flex", alignItems: "center", gap: "1rem", justifyContent: "center", letterSpacing: "0.02em" }}>
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.5)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z" />
                <path d="M5 3v4" />
                <path d="M19 17v4" />
                <path d="M3 5h4" />
                <path d="M17 19h4" />
              </svg>
              Made with Bookjet
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.5)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z" />
                <path d="M5 3v4" />
                <path d="M19 17v4" />
                <path d="M3 5h4" />
                <path d="M17 19h4" />
              </svg>
            </p>
          </div>
        </div>
      </div>
    );
  }
);

ShareableRecapCard.displayName = "ShareableRecapCard";
