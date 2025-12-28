import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { getAllQuotes, getQuoteStats } from "@/lib/db/queries";
import { Quote, Star, BookOpen, Plus } from "lucide-react";
import { AddQuoteButton } from "@/components/add-quote-button";
import { QuoteCard } from "@/components/quote-card";

export default async function QuotesPage() {
  const [quotes, stats] = await Promise.all([
    getAllQuotes(),
    getQuoteStats(),
  ]);

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight flex items-center gap-2">
            <Quote className="h-8 w-8" />
            Quotes & Highlights
          </h1>
          <p className="text-muted-foreground">
            Your collection of memorable passages
          </p>
        </div>
        <AddQuoteButton />
      </div>

      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Total Quotes</p>
                <p className="text-3xl font-bold">{stats.totalQuotes}</p>
              </div>
              <Quote className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Favorites</p>
                <p className="text-3xl font-bold">{stats.favoriteQuotes}</p>
              </div>
              <Star className="h-8 w-8 text-yellow-500 fill-yellow-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Books with Quotes</p>
                <p className="text-3xl font-bold">{stats.booksWithQuotes}</p>
              </div>
              <BookOpen className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quotes List */}
      {quotes.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-12">
            <Quote className="h-12 w-12 text-muted-foreground mb-4" />
            <h3 className="text-lg font-semibold mb-2">No quotes yet</h3>
            <p className="text-sm text-muted-foreground mb-4 text-center max-w-sm">
              Start saving your favorite quotes and memorable passages from the books you read
            </p>
            <AddQuoteButton variant="default" />
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {quotes.map((item) => (
            <QuoteCard
              key={item.quote.quoteId}
              quote={item.quote}
              book={item.book}
              authors={item.authors || "Unknown"}
            />
          ))}
        </div>
      )}
    </div>
  );
}
