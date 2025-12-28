"use client";

import { useState, useEffect, useRef } from "react";
import { MonthlyRecapData } from "@/app/actions/reading-recap";
import { X, ChevronLeft, ChevronRight, BookOpen, Star, Zap, Trophy, Calendar, Sparkles, Share2, Download } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ShareableRecapCard } from "@/components/shareable-recap-card";
import html2canvas from "html2canvas";
import { toast } from "sonner";

// Counter animation hook
function useCounter(end: number, duration: number = 2000, isActive: boolean = false) {
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (!isActive) {
      setCount(0);
      return;
    }

    let startTime: number | null = null;
    const startValue = 0;

    const animate = (currentTime: number) => {
      if (startTime === null) startTime = currentTime;
      const progress = Math.min((currentTime - startTime) / duration, 1);

      // Easing function for smooth animation
      const easeOutQuart = 1 - Math.pow(1 - progress, 4);
      setCount(Math.floor(easeOutQuart * (end - startValue) + startValue));

      if (progress < 1) {
        requestAnimationFrame(animate);
      }
    };

    requestAnimationFrame(animate);
  }, [end, duration, isActive]);

  return count;
}

// Floating particles component
function FloatingParticles({ color = "white" }: { color?: string }) {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {[...Array(20)].map((_, i) => (
        <div
          key={i}
          className="absolute rounded-full opacity-20"
          style={{
            width: Math.random() * 4 + 2 + "px",
            height: Math.random() * 4 + 2 + "px",
            background: color,
            left: Math.random() * 100 + "%",
            top: Math.random() * 100 + "%",
            animation: `float ${Math.random() * 10 + 10}s linear infinite`,
            animationDelay: Math.random() * 5 + "s",
          }}
        />
      ))}
    </div>
  );
}

// Sparkle effect component
function Sparkle({ className = "" }: { className?: string }) {
  return (
    <div className={`absolute ${className}`}>
      <Sparkles className="h-6 w-6 text-yellow-300 animate-pulse" />
    </div>
  );
}

interface MonthlyRecapProps {
  data: MonthlyRecapData;
  isOpen: boolean;
  onClose: () => void;
}

export function MonthlyRecap({ data, isOpen, onClose }: MonthlyRecapProps) {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [touchStart, setTouchStart] = useState(0);
  const [touchEnd, setTouchEnd] = useState(0);
  const [isGeneratingImage, setIsGeneratingImage] = useState(false);
  const shareableCardRef = useRef<HTMLDivElement>(null);

  const booksCount = useCounter(data.booksFinished, 2000, currentSlide === 1);
  const pagesCount = useCounter(data.pagesRead, 2500, currentSlide === 1);

  const generateShareableImage = async (type: "post" | "story" = "post") => {
    if (!shareableCardRef.current) return;

    setIsGeneratingImage(true);
    toast.info("Generating image...");

    try {
      // Wait a bit for the card to render
      await new Promise((resolve) => setTimeout(resolve, 100));

      const canvas = await html2canvas(shareableCardRef.current, {
        scale: 2, // Higher quality
        useCORS: true,
        logging: false,
        backgroundColor: null,
      });

      // Convert canvas to blob
      canvas.toBlob((blob) => {
        if (!blob) {
          toast.error("Failed to generate image");
          return;
        }

        // Create download link
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.download = `reading-recap-${data.month}-${data.year}.png`;
        link.href = url;
        link.click();

        // Cleanup
        URL.revokeObjectURL(url);
        toast.success("Image downloaded!");
      }, "image/png");
    } catch (error) {
      console.error("Error generating image:", error);
      toast.error("Failed to generate image");
    } finally {
      setIsGeneratingImage(false);
    }
  };

  const slides = [
    // Slide 1: Welcome
    {
      gradient: "from-purple-600 via-pink-600 to-red-600",
      content: (
        <div className="relative flex flex-col items-center justify-center h-full text-center px-6 overflow-hidden">
          <FloatingParticles />
          <Sparkle className="top-20 left-10 animate-ping" />
          <Sparkle className="top-40 right-20 animate-pulse" />
          <Sparkle className="bottom-32 left-1/4" />
          <Sparkle className="bottom-20 right-1/3 animate-ping" />

          <div className="mb-8 relative">
            <div className="absolute inset-0 bg-white/20 blur-3xl rounded-full animate-pulse" />
            <BookOpen className="h-24 w-24 text-white relative z-10 mx-auto mb-4 drop-shadow-2xl animate-in zoom-in duration-700"
              style={{
                filter: "drop-shadow(0 0 30px rgba(255,255,255,0.5))"
              }}
            />
          </div>

          <h1 className="text-6xl md:text-7xl font-black text-white mb-4 animate-in slide-in-from-bottom duration-700 delay-150"
            style={{
              textShadow: "0 0 40px rgba(255,255,255,0.5), 0 10px 30px rgba(0,0,0,0.3)",
              background: "linear-gradient(to bottom, white, rgba(255,255,255,0.8))",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
              backgroundClip: "text"
            }}
          >
            Your Reading
          </h1>

          <h2 className="text-5xl md:text-6xl font-black text-white mb-8 animate-in slide-in-from-bottom duration-700 delay-300"
            style={{
              textShadow: "0 0 30px rgba(255,255,255,0.4), 0 8px 20px rgba(0,0,0,0.3)"
            }}
          >
            {data.month} {data.year}
          </h2>

          <p className="text-2xl text-white/90 animate-in fade-in duration-700 delay-500 font-medium"
            style={{ textShadow: "0 2px 10px rgba(0,0,0,0.3)" }}
          >
            Let's celebrate your journey ✨
          </p>
        </div>
      ),
    },
    // Slide 2: Books & Pages
    {
      gradient: "from-blue-600 via-cyan-600 to-teal-600",
      content: (
        <div className="relative flex flex-col items-center justify-center h-full text-center px-6 overflow-hidden">
          <FloatingParticles color="rgba(255,255,255,0.6)" />

          {/* Glowing orbs in background */}
          <div className="absolute top-1/4 left-1/4 w-64 h-64 bg-white/10 rounded-full blur-3xl animate-pulse" />
          <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-cyan-300/10 rounded-full blur-3xl animate-pulse delay-700" />

          <div className="mb-12 relative z-10">
            {/* Animated number with glow */}
            <div
              className="text-9xl md:text-[12rem] font-black text-white mb-6 relative animate-in zoom-in duration-1000"
              style={{
                textShadow: "0 0 60px rgba(255,255,255,0.8), 0 0 100px rgba(96, 165, 250, 0.4), 0 20px 40px rgba(0,0,0,0.3)",
                background: "linear-gradient(to bottom, white, rgba(255,255,255,0.7))",
                WebkitBackgroundClip: "text",
                WebkitTextFillColor: "transparent",
                backgroundClip: "text"
              }}
            >
              {booksCount}
            </div>

            {/* Sparkle decorations */}
            <Sparkle className="-top-4 -right-8" />
            <Sparkle className="-bottom-4 -left-8" />

            <h2 className="text-4xl md:text-5xl font-bold text-white animate-in slide-in-from-bottom duration-700 delay-300"
              style={{ textShadow: "0 4px 20px rgba(0,0,0,0.3)" }}
            >
              {data.booksFinished === 1 ? "Book Finished" : "Books Finished"}
            </h2>
          </div>

          {/* Pages card with animated border */}
          <div className="relative animate-in slide-in-from-bottom duration-700 delay-500">
            <div className="absolute inset-0 bg-gradient-to-r from-white/30 to-cyan-300/30 rounded-3xl blur-xl" />
            <div className="relative bg-white/20 backdrop-blur-md rounded-3xl px-12 py-8 border-2 border-white/30">
              <div
                className="text-6xl md:text-7xl font-black text-white mb-3"
                style={{
                  textShadow: "0 0 30px rgba(255,255,255,0.5), 0 4px 15px rgba(0,0,0,0.3)"
                }}
              >
                {pagesCount.toLocaleString()}
              </div>
              <p className="text-2xl text-white/95 font-semibold flex items-center gap-2 justify-center">
                <BookOpen className="h-6 w-6" />
                Pages Read
              </p>
            </div>
          </div>
        </div>
      ),
    },
    // Slide 3: Top Genre
    ...(data.topGenre
      ? [
          {
            gradient: "from-orange-600 via-red-600 to-pink-600",
            content: (
              <div className="relative flex flex-col items-center justify-center h-full text-center px-6 overflow-hidden">
                <FloatingParticles color="rgba(255,215,0,0.4)" />

                {/* Animated trophy with glow */}
                <div className="mb-10 relative animate-in zoom-in duration-1000">
                  <div className="absolute inset-0 bg-yellow-300/40 blur-3xl rounded-full animate-pulse" />
                  <Trophy
                    className="h-32 w-32 text-yellow-300 relative z-10 mx-auto mb-6 animate-bounce"
                    style={{
                      filter: "drop-shadow(0 0 40px rgba(253, 224, 71, 0.8)) drop-shadow(0 10px 30px rgba(0,0,0,0.4))"
                    }}
                  />
                  <Sparkle className="-top-6 -right-6 animate-ping" />
                  <Sparkle className="-bottom-6 -left-6 animate-pulse" />
                  <Sparkle className="top-1/2 -right-10" />
                </div>

                <h2 className="text-4xl md:text-5xl font-bold text-white mb-12 animate-in slide-in-from-bottom duration-700 delay-200"
                  style={{
                    textShadow: "0 4px 20px rgba(0,0,0,0.4)"
                  }}
                >
                  Your Favorite Genre
                </h2>

                {/* Genre badge with 3D effect */}
                <div className="relative animate-in slide-in-from-bottom duration-700 delay-400">
                  <div className="absolute inset-0 bg-gradient-to-br from-yellow-400/30 to-orange-400/30 rounded-3xl blur-2xl scale-110" />
                  <div className="relative bg-gradient-to-br from-white/25 to-white/10 backdrop-blur-md rounded-3xl px-16 py-10 border-2 border-white/40 shadow-2xl">
                    <div
                      className="text-5xl md:text-6xl font-black text-white"
                      style={{
                        textShadow: "0 0 40px rgba(255,255,255,0.6), 0 6px 25px rgba(0,0,0,0.4)",
                        background: "linear-gradient(to bottom, white, rgba(255,255,255,0.85))",
                        WebkitBackgroundClip: "text",
                        WebkitTextFillColor: "transparent",
                        backgroundClip: "text"
                      }}
                    >
                      {data.topGenre}
                    </div>
                  </div>
                </div>
              </div>
            ),
          },
        ]
      : []),
    // Slide 4: Top Rated Book
    ...(data.topRatedBook
      ? [
          {
            gradient: "from-yellow-600 via-orange-600 to-red-600",
            content: (
              <div className="flex flex-col items-center justify-center h-full text-center px-6">
                <div className="mb-6">
                  <Star className="h-16 w-16 text-yellow-300 fill-yellow-300 mx-auto mb-4" />
                </div>
                <h2 className="text-3xl md:text-4xl font-bold text-white mb-6">
                  Top Rated Book
                </h2>
                <div className="bg-white/20 backdrop-blur-sm rounded-2xl px-8 py-8 max-w-md">
                  <div className="text-3xl md:text-4xl font-bold text-white mb-3">
                    {data.topRatedBook.title}
                  </div>
                  <p className="text-lg text-white/80 mb-4">
                    by {data.topRatedBook.authors}
                  </p>
                  <div className="flex items-center justify-center gap-2">
                    <Star className="h-8 w-8 text-yellow-300 fill-yellow-300" />
                    <span className="text-4xl font-bold text-white">
                      {data.topRatedBook.rating}
                    </span>
                    <span className="text-2xl text-white/80">/5</span>
                  </div>
                </div>
              </div>
            ),
          },
        ]
      : []),
    // Slide 5: Fastest Book
    ...(data.fastestBook
      ? [
          {
            gradient: "from-green-600 via-emerald-600 to-teal-600",
            content: (
              <div className="flex flex-col items-center justify-center h-full text-center px-6">
                <div className="mb-6">
                  <Zap className="h-16 w-16 text-yellow-300 fill-yellow-300 mx-auto mb-4" />
                </div>
                <h2 className="text-3xl md:text-4xl font-bold text-white mb-6">
                  Fastest Read
                </h2>
                <div className="bg-white/20 backdrop-blur-sm rounded-2xl px-8 py-8 max-w-md">
                  <div className="text-3xl md:text-4xl font-bold text-white mb-4">
                    {data.fastestBook.title}
                  </div>
                  <div className="flex items-center justify-center gap-2">
                    <Calendar className="h-6 w-6 text-white/80" />
                    <span className="text-2xl font-bold text-white">
                      {data.fastestBook.days} {data.fastestBook.days === 1 ? "day" : "days"}
                    </span>
                  </div>
                </div>
              </div>
            ),
          },
        ]
      : []),
    // Slide 6: Favorite Author
    ...(data.favoriteAuthor
      ? [
          {
            gradient: "from-indigo-600 via-purple-600 to-pink-600",
            content: (
              <div className="flex flex-col items-center justify-center h-full text-center px-6">
                <h2 className="text-3xl md:text-4xl font-bold text-white mb-8">
                  Your Favorite Author
                </h2>
                <div className="bg-white/20 backdrop-blur-sm rounded-2xl px-12 py-8">
                  <div className="text-4xl md:text-5xl font-bold text-white">
                    {data.favoriteAuthor}
                  </div>
                </div>
              </div>
            ),
          },
        ]
      : []),
    // Slide 7: Summary
    {
      gradient: "from-slate-800 via-slate-900 to-black",
      content: (
        <div className="flex flex-col items-center justify-center h-full text-center px-6">
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-12">
            Keep Reading!
          </h2>
          <div className="grid grid-cols-2 gap-6 max-w-2xl w-full mb-12">
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6">
              <div className="text-4xl font-bold text-white mb-2">
                {data.booksFinished}
              </div>
              <p className="text-sm text-white/70">Books</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6">
              <div className="text-4xl font-bold text-white mb-2">
                {data.pagesRead.toLocaleString()}
              </div>
              <p className="text-sm text-white/70">Pages</p>
            </div>
            {data.totalReadingDays > 0 && (
              <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6">
                <div className="text-4xl font-bold text-white mb-2">
                  {data.totalReadingDays}
                </div>
                <p className="text-sm text-white/70">Reading Days</p>
              </div>
            )}
            {data.topGenre && (
              <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6">
                <div className="text-2xl font-bold text-white mb-2">
                  {data.topGenre}
                </div>
                <p className="text-sm text-white/70">Top Genre</p>
              </div>
            )}
          </div>

          {/* Share Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 mb-8">
            <Button
              onClick={() => generateShareableImage("post")}
              disabled={isGeneratingImage}
              size="lg"
              className="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white px-8 py-6 text-lg"
            >
              <Share2 className="mr-2 h-5 w-5" />
              {isGeneratingImage ? "Generating..." : "Share to Instagram"}
            </Button>
            <Button
              onClick={() => generateShareableImage("story")}
              disabled={isGeneratingImage}
              size="lg"
              variant="outline"
              className="bg-white/10 hover:bg-white/20 text-white border-white/30 px-8 py-6 text-lg backdrop-blur-sm"
            >
              <Download className="mr-2 h-5 w-5" />
              Download Story
            </Button>
          </div>

          <p className="text-lg text-white/60">
            {data.month} {data.year}
          </p>
        </div>
      ),
    },
  ];

  const totalSlides = slides.length;

  const nextSlide = () => {
    if (currentSlide < totalSlides - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      onClose();
    }
  };

  const prevSlide = () => {
    if (currentSlide > 0) {
      setCurrentSlide(currentSlide - 1);
    }
  };

  const handleTouchStart = (e: React.TouchEvent) => {
    setTouchStart(e.targetTouches[0].clientX);
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    setTouchEnd(e.targetTouches[0].clientX);
  };

  const handleTouchEnd = () => {
    if (!touchStart || !touchEnd) return;

    const distance = touchStart - touchEnd;
    const minSwipeDistance = 50;

    if (distance > minSwipeDistance) {
      // Swipe left - next slide
      nextSlide();
    }

    if (distance < -minSwipeDistance) {
      // Swipe right - previous slide
      prevSlide();
    }

    setTouchStart(0);
    setTouchEnd(0);
  };

  useEffect(() => {
    if (isOpen) {
      setCurrentSlide(0);
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "unset";
    }

    return () => {
      document.body.style.overflow = "unset";
    };
  }, [isOpen]);

  // Keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!isOpen) return;

      if (e.key === "ArrowRight") nextSlide();
      if (e.key === "ArrowLeft") prevSlide();
      if (e.key === "Escape") onClose();
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, currentSlide]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 overflow-hidden">
      {/* Background with current slide gradient */}
      <div
        className={`absolute inset-0 bg-gradient-to-br ${slides[currentSlide].gradient} transition-all duration-500`}
      />

      {/* Progress bars */}
      <div className="absolute top-4 left-4 right-4 flex gap-1 z-10">
        {slides.map((_, index) => (
          <div
            key={index}
            className="h-1 flex-1 bg-white/30 rounded-full overflow-hidden"
          >
            <div
              className={`h-full bg-white transition-all duration-300 ${
                index < currentSlide
                  ? "w-full"
                  : index === currentSlide
                  ? "w-full"
                  : "w-0"
              }`}
            />
          </div>
        ))}
      </div>

      {/* Close button */}
      <Button
        variant="ghost"
        size="icon"
        onClick={onClose}
        className="absolute top-4 right-4 z-10 text-white hover:bg-white/20"
      >
        <X className="h-6 w-6" />
      </Button>

      {/* Main content area with touch handlers */}
      <div
        className="absolute inset-0 flex items-center justify-center"
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      >
        <div className="w-full h-full max-w-2xl relative">
          {/* Slide content with animation */}
          <div
            key={currentSlide}
            className="w-full h-full animate-in fade-in slide-in-from-right-4 duration-300"
          >
            {slides[currentSlide].content}
          </div>
        </div>
      </div>

      {/* Navigation buttons (desktop) */}
      <div className="absolute inset-y-0 left-0 right-0 flex items-center justify-between px-4 pointer-events-none">
        {currentSlide > 0 && (
          <Button
            variant="ghost"
            size="icon"
            onClick={prevSlide}
            className="pointer-events-auto text-white hover:bg-white/20 h-12 w-12"
          >
            <ChevronLeft className="h-8 w-8" />
          </Button>
        )}
        <div className="flex-1" />
        {currentSlide < totalSlides - 1 && (
          <Button
            variant="ghost"
            size="icon"
            onClick={nextSlide}
            className="pointer-events-auto text-white hover:bg-white/20 h-12 w-12"
          >
            <ChevronRight className="h-8 w-8" />
          </Button>
        )}
      </div>

      {/* Tap areas for mobile (invisible) */}
      <div className="absolute inset-0 flex md:hidden">
        <div
          className="flex-1"
          onClick={prevSlide}
          style={{ opacity: 0 }}
        />
        <div
          className="flex-1"
          onClick={nextSlide}
          style={{ opacity: 0 }}
        />
      </div>

      {/* Off-screen shareable card for image generation */}
      <div className="fixed -left-[9999px] -top-[9999px]">
        <ShareableRecapCard ref={shareableCardRef} data={data} type="post" />
      </div>
    </div>
  );
}
