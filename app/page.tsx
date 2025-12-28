import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  BookOpen,
  Target,
  Quote,
  Flame,
  TrendingUp,
  BarChart3,
  ArrowRight,
  Star
} from "lucide-react";

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted/20">
      {/* Hero Section */}
      <div className="container mx-auto px-4 py-16 md:py-24">
        <div className="flex flex-col items-center text-center space-y-8 max-w-4xl mx-auto">
          {/* Logo/Icon */}
          <div className="flex items-center justify-center w-20 h-20 rounded-2xl bg-primary/10">
            <BookOpen className="w-12 h-12 text-primary" />
          </div>

          {/* Heading */}
          <div className="space-y-4">
            <h1 className="text-5xl md:text-7xl font-bold tracking-tight">
              Bookjet
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-2xl">
              Your personal reading companion. Track books, build streaks, save quotes, and achieve your reading goals.
            </p>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 pt-4">
            <Button asChild size="lg" className="text-lg px-8">
              <Link href="/dashboard">
                Get Started
                <ArrowRight className="ml-2 h-5 w-5" />
              </Link>
            </Button>
            <Button asChild variant="outline" size="lg" className="text-lg px-8">
              <Link href="/sign-in">
                Sign In
              </Link>
            </Button>
          </div>

          {/* Stats Preview */}
          <div className="grid grid-cols-3 gap-8 pt-8 w-full max-w-2xl">
            <div className="text-center">
              <div className="text-3xl font-bold text-primary">1.1k+</div>
              <div className="text-sm text-muted-foreground">Books Tracked</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-primary">365</div>
              <div className="text-sm text-muted-foreground">Day Streaks</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-primary">500+</div>
              <div className="text-sm text-muted-foreground">Quotes Saved</div>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="container mx-auto px-4 py-16">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Everything you need to track your reading
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Powerful features designed for book lovers who want to build better reading habits
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto">
          {/* Feature 1 */}
          <Card className="border-2 hover:border-primary/50 transition-colors">
            <CardContent className="pt-6">
              <div className="flex flex-col items-start space-y-4">
                <div className="p-3 rounded-lg bg-orange-500/10">
                  <Flame className="w-6 h-6 text-orange-500" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold mb-2">Reading Streaks</h3>
                  <p className="text-muted-foreground">
                    GitHub-style heatmap showing 365 days of reading activity. Build streaks and stay motivated.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Feature 2 */}
          <Card className="border-2 hover:border-primary/50 transition-colors">
            <CardContent className="pt-6">
              <div className="flex flex-col items-start space-y-4">
                <div className="p-3 rounded-lg bg-blue-500/10">
                  <Target className="w-6 h-6 text-blue-500" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold mb-2">Reading Goals</h3>
                  <p className="text-muted-foreground">
                    Set annual reading targets and track your progress. Know exactly where you stand.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Feature 3 */}
          <Card className="border-2 hover:border-primary/50 transition-colors">
            <CardContent className="pt-6">
              <div className="flex flex-col items-start space-y-4">
                <div className="p-3 rounded-lg bg-purple-500/10">
                  <Quote className="w-6 h-6 text-purple-500" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold mb-2">Quotes & Highlights</h3>
                  <p className="text-muted-foreground">
                    Save memorable passages with tags, notes, and page numbers. Never lose a great quote.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Feature 4 */}
          <Card className="border-2 hover:border-primary/50 transition-colors">
            <CardContent className="pt-6">
              <div className="flex flex-col items-start space-y-4">
                <div className="p-3 rounded-lg bg-green-500/10">
                  <TrendingUp className="w-6 h-6 text-green-500" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold mb-2">Progress Tracking</h3>
                  <p className="text-muted-foreground">
                    Log reading sessions with pages read and time spent. See your reading patterns.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Feature 5 */}
          <Card className="border-2 hover:border-primary/50 transition-colors">
            <CardContent className="pt-6">
              <div className="flex flex-col items-start space-y-4">
                <div className="p-3 rounded-lg bg-yellow-500/10">
                  <Star className="w-6 h-6 text-yellow-500" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold mb-2">Ratings & Reviews</h3>
                  <p className="text-muted-foreground">
                    Rate books, write reviews, and keep track of your favorites all in one place.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Feature 6 */}
          <Card className="border-2 hover:border-primary/50 transition-colors">
            <CardContent className="pt-6">
              <div className="flex flex-col items-start space-y-4">
                <div className="p-3 rounded-lg bg-indigo-500/10">
                  <BarChart3 className="w-6 h-6 text-indigo-500" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold mb-2">Rich Analytics</h3>
                  <p className="text-muted-foreground">
                    Detailed statistics, reading history charts, and insights about your reading habits.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* CTA Section */}
      <div className="container mx-auto px-4 py-16">
        <Card className="bg-primary text-primary-foreground border-0">
          <CardContent className="py-12 px-6">
            <div className="flex flex-col items-center text-center space-y-6 max-w-2xl mx-auto">
              <h2 className="text-3xl md:text-4xl font-bold">
                Ready to transform your reading journey?
              </h2>
              <p className="text-lg opacity-90">
                Join thousands of readers tracking their books, building streaks, and achieving their reading goals with Bookjet.
              </p>
              <Button asChild size="lg" variant="secondary" className="text-lg px-8">
                <Link href="/dashboard">
                  Start Reading Now
                  <ArrowRight className="ml-2 h-5 w-5" />
                </Link>
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Footer */}
      <footer className="border-t py-8">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4 text-sm text-muted-foreground">
            <div className="flex items-center gap-2">
              <BookOpen className="w-4 h-4" />
              <span>© 2025 Bookjet v1.1.0</span>
            </div>
            <div className="flex gap-6">
              <Link href="/dashboard" className="hover:text-foreground transition-colors">
                Dashboard
              </Link>
              <Link href="/sign-in" className="hover:text-foreground transition-colors">
                Sign In
              </Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
