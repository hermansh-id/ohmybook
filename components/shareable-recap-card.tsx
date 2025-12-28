"use client";

import { MonthlyRecapData } from "@/app/actions/reading-recap";
import { forwardRef } from "react";

interface ShareableRecapCardProps {
  data: MonthlyRecapData;
  type?: "post" | "story";
}

export const ShareableRecapCard = forwardRef<HTMLDivElement, ShareableRecapCardProps>(
  ({ data, type = "post" }, ref) => {
    const isStory = type === "story";

    return (
      <div
        ref={ref}
        style={{
          position: "relative",
          overflow: "hidden",
          width: "1080px",
          height: isStory ? "1920px" : "1350px",
          background: "linear-gradient(135deg, #667eea 0%, #764ba2 25%, #f093fb 50%, #4facfe 75%, #00f2fe 100%)",
          fontFamily: "system-ui, -apple-system, sans-serif",
        }}
      >
        {/* Decorative background elements */}
        <div style={{ position: "absolute", inset: 0 }}>
          <div style={{ position: "absolute", top: "5rem", left: "5rem", width: "24rem", height: "24rem", background: "rgba(255,255,255,0.1)", borderRadius: "9999px", filter: "blur(48px)" }} />
          <div style={{ position: "absolute", bottom: "5rem", right: "5rem", width: "500px", height: "500px", background: "rgba(216, 180, 254, 0.1)", borderRadius: "9999px", filter: "blur(48px)" }} />

          {[...Array(30)].map((_, i) => (
            <div
              key={i}
              style={{
                position: "absolute",
                borderRadius: "9999px",
                background: "rgba(255,255,255,0.2)",
                width: Math.random() * 8 + 4 + "px",
                height: Math.random() * 8 + 4 + "px",
                left: Math.random() * 100 + "%",
                top: Math.random() * 100 + "%",
              }}
            />
          ))}
        </div>

        {/* Content */}
        <div style={{ position: "relative", zIndex: 10, height: "100%", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "6rem 5rem" }}>
          {/* Header */}
          <div style={{ textAlign: "center", marginBottom: "4rem" }}>
            <div style={{ marginBottom: "2rem", display: "inline-block", position: "relative" }}>
              <svg width="128" height="128" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ filter: "drop-shadow(0 0 40px rgba(255,255,255,0.6))" }}>
                <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20" />
              </svg>
            </div>
            <h1 style={{ fontSize: "8rem", fontWeight: 900, color: "white", marginBottom: "1.5rem", textShadow: "0 0 60px rgba(255,255,255,0.5), 0 10px 40px rgba(0,0,0,0.3)" }}>
              My Reading
            </h1>
            <h2 style={{ fontSize: "7rem", fontWeight: 900, color: "white", textShadow: "0 0 40px rgba(255,255,255,0.4), 0 8px 30px rgba(0,0,0,0.3)" }}>
              {data.month} {data.year}
            </h2>
          </div>

          {/* Stats Grid */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "2rem", width: "100%", maxWidth: "1000px", marginBottom: "3rem" }}>
            {/* Books */}
            <div style={{ position: "relative" }}>
              <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to bottom right, rgba(255,255,255,0.3), rgba(255,255,255,0.1))", borderRadius: "1.5rem", filter: "blur(16px)" }} />
              <div style={{ position: "relative", background: "rgba(255,255,255,0.2)", backdropFilter: "blur(12px)", borderRadius: "1.5rem", padding: "2.5rem", border: "2px solid rgba(255,255,255,0.3)", textAlign: "center" }}>
                <div style={{ fontSize: "8rem", fontWeight: 900, color: "white", marginBottom: "1rem", textShadow: "0 0 40px rgba(255,255,255,0.6), 0 6px 25px rgba(0,0,0,0.3)" }}>
                  {data.booksFinished}
                </div>
                <p style={{ fontSize: "3rem", fontWeight: 700, color: "rgba(255,255,255,0.9)" }}>
                  {data.booksFinished === 1 ? "Book" : "Books"}
                </p>
              </div>
            </div>

            {/* Pages */}
            <div style={{ position: "relative" }}>
              <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to bottom right, rgba(255,255,255,0.3), rgba(255,255,255,0.1))", borderRadius: "1.5rem", filter: "blur(16px)" }} />
              <div style={{ position: "relative", background: "rgba(255,255,255,0.2)", backdropFilter: "blur(12px)", borderRadius: "1.5rem", padding: "2.5rem", border: "2px solid rgba(255,255,255,0.3)", textAlign: "center" }}>
                <div style={{ fontSize: "8rem", fontWeight: 900, color: "white", marginBottom: "1rem", textShadow: "0 0 40px rgba(255,255,255,0.6), 0 6px 25px rgba(0,0,0,0.3)" }}>
                  {data.pagesRead.toLocaleString()}
                </div>
                <p style={{ fontSize: "3rem", fontWeight: 700, color: "rgba(255,255,255,0.9)" }}>Pages</p>
              </div>
            </div>
          </div>

          {/* Additional Stats */}
          <div style={{ display: "flex", flexDirection: "column", gap: "1.5rem", width: "100%", maxWidth: "1000px" }}>
            {/* Top Genre */}
            {data.topGenre && (
              <div style={{ position: "relative" }}>
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to right, rgba(250, 204, 21, 0.2), rgba(251, 146, 60, 0.2))", borderRadius: "1rem", filter: "blur(12px)" }} />
                <div style={{ position: "relative", background: "rgba(255,255,255,0.15)", backdropFilter: "blur(12px)", borderRadius: "1rem", padding: "1.5rem 2rem", border: "1px solid rgba(255,255,255,0.3)", display: "flex", alignItems: "center", gap: "1.5rem" }}>
                  <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#fde047" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ filter: "drop-shadow(0 0 20px rgba(253, 224, 71, 0.6))", flexShrink: 0 }}>
                    <path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6" />
                    <path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18" />
                    <path d="M4 22h16" />
                    <path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22" />
                    <path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22" />
                    <path d="M18 2H6v7a6 6 0 0 0 12 0V2Z" />
                  </svg>
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: "2rem", color: "rgba(255,255,255,0.7)", fontWeight: 600, marginBottom: "0.25rem" }}>Favorite Genre</p>
                    <p style={{ fontSize: "4rem", fontWeight: 900, color: "white", textShadow: "0 2px 15px rgba(0,0,0,0.3)" }}>
                      {data.topGenre}
                    </p>
                  </div>
                </div>
              </div>
            )}

            {/* Top Rated Book */}
            {data.topRatedBook && (
              <div style={{ position: "relative" }}>
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to right, rgba(250, 204, 21, 0.2), rgba(244, 114, 182, 0.2))", borderRadius: "1rem", filter: "blur(12px)" }} />
                <div style={{ position: "relative", background: "rgba(255,255,255,0.15)", backdropFilter: "blur(12px)", borderRadius: "1rem", padding: "1.5rem 2rem", border: "1px solid rgba(255,255,255,0.3)", display: "flex", alignItems: "center", gap: "1.5rem" }}>
                  <svg width="64" height="64" viewBox="0 0 24 24" fill="#fde047" stroke="#fde047" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ filter: "drop-shadow(0 0 20px rgba(253, 224, 71, 0.6))", flexShrink: 0 }}>
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                  </svg>
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: "2rem", color: "rgba(255,255,255,0.7)", fontWeight: 600, marginBottom: "0.25rem" }}>Top Rated</p>
                    <p style={{ fontSize: "3rem", fontWeight: 900, color: "white", marginBottom: "0.25rem", textShadow: "0 2px 15px rgba(0,0,0,0.3)" }}>
                      {data.topRatedBook.title}
                    </p>
                    <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
                      <p style={{ fontSize: "2rem", color: "rgba(255,255,255,0.8)" }}>by {data.topRatedBook.authors}</p>
                      <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", background: "rgba(255,255,255,0.2)", padding: "0.5rem 1rem", borderRadius: "9999px" }}>
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="#fde047" stroke="#fde047" strokeWidth="2">
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
                <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to right, rgba(74, 222, 128, 0.2), rgba(45, 212, 191, 0.2))", borderRadius: "1rem", filter: "blur(12px)" }} />
                <div style={{ position: "relative", background: "rgba(255,255,255,0.15)", backdropFilter: "blur(12px)", borderRadius: "1rem", padding: "1.5rem 2rem", border: "1px solid rgba(255,255,255,0.3)", display: "flex", alignItems: "center", gap: "1.5rem" }}>
                  <svg width="64" height="64" viewBox="0 0 24 24" fill="#fde047" stroke="#fde047" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ filter: "drop-shadow(0 0 20px rgba(253, 224, 71, 0.6))", flexShrink: 0 }}>
                    <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
                  </svg>
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: "2rem", color: "rgba(255,255,255,0.7)", fontWeight: 600, marginBottom: "0.25rem" }}>Fastest Read</p>
                    <p style={{ fontSize: "3rem", fontWeight: 900, color: "white", marginBottom: "0.25rem", textShadow: "0 2px 15px rgba(0,0,0,0.3)" }}>
                      {data.fastestBook.title}
                    </p>
                    <p style={{ fontSize: "2rem", color: "rgba(255,255,255,0.8)" }}>
                      {data.fastestBook.days} {data.fastestBook.days === 1 ? "day" : "days"}
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Footer */}
          <div style={{ marginTop: "4rem", textAlign: "center" }}>
            <p style={{ fontSize: "3rem", color: "rgba(255,255,255,0.6)", fontWeight: 600, display: "flex", alignItems: "center", gap: "0.75rem", justifyContent: "center" }}>
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z" />
                <path d="M5 3v4" />
                <path d="M19 17v4" />
                <path d="M3 5h4" />
                <path d="M17 19h4" />
              </svg>
              Made with Bookjet
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.6)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
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
