import { getReadingRecommendationsAction } from "@/app/actions/books";
import { BookOpen, Star, Calendar, TrendingUp } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import Link from "next/link";

export default async function RecommendationsPage() {
  const recommendations = await getReadingRecommendationsAction();

  return (
    <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
      <div className="flex items-center justify-between">
        <h2 className="text-3xl font-bold tracking-tight">What to Read Next</h2>
      </div>

      {recommendations.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-lg border border-dashed p-8 text-center min-h-[400px]">
          <BookOpen className="h-12 w-12 text-muted-foreground" />
          <h3 className="mt-4 text-lg font-semibold">No recommendations yet</h3>
          <p className="text-muted-foreground mt-2 max-w-sm">
            Add unread books to your library to get personalized recommendations
          </p>
        </div>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {recommendations.map((book, index) => (
            <Link
              key={book.id}
              href={`/dashboard/books/${book.id}`}
              className="group"
            >
              <div className="rounded-lg border bg-card p-4 hover:bg-accent transition-colors h-full">
                <div className="flex gap-4">
                  {/* Book Cover */}
                  {book.coverUrl ? (
                    <img
                      src={book.coverUrl}
                      alt={book.title}
                      className="w-16 h-24 object-cover rounded shadow-sm flex-shrink-0"
                    />
                  ) : (
                    <div className="w-16 h-24 bg-muted rounded flex items-center justify-center flex-shrink-0">
                      <BookOpen className="h-6 w-6 text-muted-foreground" />
                    </div>
                  )}

                  {/* Book Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start gap-2 mb-1">
                      <Badge variant="outline" className="text-xs">#{index + 1}</Badge>
                      {book.status === "reading" && (
                        <Badge className="text-xs">Reading</Badge>
                      )}
                    </div>

                    <h3 className="font-semibold line-clamp-2 group-hover:text-primary transition-colors mb-1">
                      {book.title}
                    </h3>

                    {book.authors.length > 0 && (
                      <p className="text-sm text-muted-foreground line-clamp-1">
                        {book.authors.map((a: any) => a.name).join(", ")}
                      </p>
                    )}

                    {/* Stats */}
                    <div className="flex items-center gap-3 mt-2 text-xs text-muted-foreground">
                      {book.averageRating && (
                        <div className="flex items-center gap-1">
                          <Star className="h-3 w-3 fill-yellow-500 text-yellow-500" />
                          <span>{book.averageRating}</span>
                        </div>
                      )}
                      {book.pages && <span>{book.pages}p</span>}
                    </div>
                  </div>
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
