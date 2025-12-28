import { getAuthorsWithStats } from "@/lib/db/queries";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { User, BookOpen, FileText, Star } from "lucide-react";

export default async function AuthorsPage() {
  const authors = await getAuthorsWithStats();

  const totalAuthors = authors.length;
  const totalBooks = authors.reduce((sum, a) => sum + a.totalBooks, 0);

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Authors</h1>
        <p className="text-muted-foreground">
          Browse authors in your collection
        </p>
      </div>

      {/* Statistics */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Total Authors</p>
              <p className="text-2xl font-bold">{totalAuthors}</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Total Books</p>
              <p className="text-2xl font-bold">{totalBooks}</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Avg Books/Author</p>
              <p className="text-2xl font-bold">
                {totalAuthors > 0 ? (totalBooks / totalAuthors).toFixed(1) : 0}
              </p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Authors List */}
      <Card>
        <CardHeader>
          <CardTitle>All Authors</CardTitle>
        </CardHeader>
        <CardContent>
          {authors.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <User className="mb-4 h-12 w-12 text-muted-foreground" />
              <p className="text-lg font-medium">No authors yet</p>
              <p className="text-sm text-muted-foreground">
                Add books to see authors
              </p>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {authors.map((item) => (
                <Card key={item.author.authorId} className="transition-shadow hover:shadow-md">
                  <CardContent className="pt-6">
                    <div className="space-y-3">
                      <div className="flex items-start justify-between">
                        <div className="flex items-center gap-2">
                          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
                            <User className="h-5 w-5 text-primary" />
                          </div>
                          <div>
                            <h3 className="font-semibold">{item.author.name}</h3>
                          </div>
                        </div>
                      </div>

                      {item.author.bio && (
                        <p className="text-sm text-muted-foreground line-clamp-2">
                          {item.author.bio}
                        </p>
                      )}

                      <div className="grid grid-cols-2 gap-2 text-sm">
                        <div className="flex items-center gap-1 text-muted-foreground">
                          <BookOpen className="h-4 w-4" />
                          <span>{item.totalBooks} books</span>
                        </div>
                        <div className="flex items-center gap-1 text-muted-foreground">
                          <FileText className="h-4 w-4" />
                          <span>{item.totalPages} pages</span>
                        </div>
                      </div>

                      <div className="flex items-center justify-between pt-2 border-t">
                        <Badge variant={item.booksRead > 0 ? "default" : "secondary"}>
                          {item.booksRead} read
                        </Badge>
                        {item.averageRating > 0 && (
                          <div className="flex items-center gap-1 text-sm">
                            <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                            <span className="font-medium">{item.averageRating}</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
