"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import * as z from "zod";
import { Check, ChevronsUpDown, X, Plus, Search, Loader2 } from "lucide-react";

import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { addBookAction, getAuthorsAction, lookupBookByISBN } from "@/app/actions/books";
import { addAuthor } from "@/app/actions/authors";

const formSchema = z.object({
  title: z.string().min(1, "Title is required"),
  isbn: z.string().optional(),
  goodreadsUrl: z.string().url("Must be a valid URL").optional().or(z.literal("")),
  year: z.number().int().min(1000).max(9999).optional().nullable(),
  pages: z.number().int().min(1).optional().nullable(),
});

type FormValues = z.infer<typeof formSchema>;

interface Author {
  authorId: number;
  name: string;
}

export default function AddBookPage() {
  const router = useRouter();
  const [authors, setAuthors] = useState<Author[]>([]);
  const [selectedAuthors, setSelectedAuthors] = useState<Author[]>([]);
  const [open, setOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showAddAuthorDialog, setShowAddAuthorDialog] = useState(false);
  const [newAuthorName, setNewAuthorName] = useState("");
  const [newAuthorBio, setNewAuthorBio] = useState("");
  const [isAddingAuthor, setIsAddingAuthor] = useState(false);
  const [isLookingUp, setIsLookingUp] = useState(false);
  const [lookupError, setLookupError] = useState<string | null>(null);

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      title: "",
      isbn: "",
      goodreadsUrl: "",
      year: null,
      pages: null,
    },
  });

  // Load authors
  useEffect(() => {
    async function loadAuthors() {
      const data = await getAuthorsAction();
      setAuthors(data);
    }
    loadAuthors();
  }, []);

  async function onSubmit(values: FormValues) {
    if (selectedAuthors.length === 0) {
      alert("Please select at least one author");
      return;
    }

    setIsSubmitting(true);
    try {
      const result = await addBookAction({
        title: values.title,
        isbn: values.isbn,
        goodreadsUrl: values.goodreadsUrl,
        year: values.year ?? undefined,
        pages: values.pages ?? undefined,
        authorIds: selectedAuthors.map((a) => a.authorId),
      });

      if (result.success) {
        router.push("/dashboard/books");
      } else {
        alert(result.error || "Failed to add book");
      }
    } catch (error) {
      alert("Failed to add book");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleAddAuthor() {
    if (!newAuthorName.trim()) {
      alert("Author name is required");
      return;
    }

    setIsAddingAuthor(true);
    try {
      const result = await addAuthor({
        name: newAuthorName.trim(),
        bio: newAuthorBio.trim() || undefined,
      });

      if (result.success && result.author) {
        // Add to authors list
        const newAuthor = {
          authorId: result.author.authorId,
          name: result.author.name,
        };
        setAuthors((prev) => [...prev, newAuthor].sort((a, b) => a.name.localeCompare(b.name)));

        // Auto-select the new author
        setSelectedAuthors((prev) => [...prev, newAuthor]);

        // Reset and close dialog
        setNewAuthorName("");
        setNewAuthorBio("");
        setShowAddAuthorDialog(false);
      } else {
        alert(result.error || "Failed to add author");
      }
    } catch (error) {
      alert("Failed to add author");
    } finally {
      setIsAddingAuthor(false);
    }
  }

  function toggleAuthor(author: Author) {
    setSelectedAuthors((prev) => {
      const exists = prev.find((a) => a.authorId === author.authorId);
      if (exists) {
        return prev.filter((a) => a.authorId !== author.authorId);
      }
      return [...prev, author];
    });
  }

  function removeAuthor(authorId: number) {
    setSelectedAuthors((prev) => prev.filter((a) => a.authorId !== authorId));
  }

  async function handleIsbnLookup() {
    const isbn = form.getValues("isbn");
    if (!isbn || !isbn.trim()) {
      setLookupError("Please enter an ISBN first");
      return;
    }

    setIsLookingUp(true);
    setLookupError(null);

    try {
      const result = await lookupBookByISBN(isbn.trim());

      if (!result.success || !result.data) {
        setLookupError(result.error || "Book not found");
        return;
      }

      const { data } = result;

      // Auto-fill form fields
      form.setValue("title", data.title);
      if (data.year) form.setValue("year", data.year);
      if (data.pages) form.setValue("pages", data.pages);
      if (data.goodreadsUrl) form.setValue("goodreadsUrl", data.goodreadsUrl);

      // Handle authors
      if (data.authors && data.authors.length > 0) {
        const authorsToSelect: Author[] = [];

        for (const authorName of data.authors) {
          // Check if author already exists in database
          let existingAuthor = authors.find(
            (a) => a.name.toLowerCase() === authorName.toLowerCase()
          );

          // If not, create new author
          if (!existingAuthor) {
            const addResult = await addAuthor({ name: authorName });
            if (addResult.success && addResult.author) {
              const newAuthor = {
                authorId: addResult.author.authorId,
                name: addResult.author.name,
              };
              setAuthors((prev) => [...prev, newAuthor].sort((a, b) => a.name.localeCompare(b.name)));
              existingAuthor = newAuthor;
            }
          }

          if (existingAuthor) {
            authorsToSelect.push(existingAuthor);
          }
        }

        setSelectedAuthors(authorsToSelect);
      }

      // Show success
      setLookupError(null);
    } catch (error) {
      console.error("Lookup error:", error);
      setLookupError("An error occurred during lookup");
    } finally {
      setIsLookingUp(false);
    }
  }

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div>
        <h1 className="text-2xl font-bold md:text-3xl">Add New Book</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Add a book to your collection
        </p>
      </div>

      <div className="mx-auto w-full max-w-2xl">

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <FormField
            control={form.control}
            name="isbn"
            render={({ field }) => (
              <FormItem>
                <FormLabel>ISBN</FormLabel>
                <div className="flex gap-2">
                  <FormControl>
                    <Input placeholder="Enter ISBN (10 or 13 digits)" {...field} />
                  </FormControl>
                  <Button
                    type="button"
                    variant="outline"
                    onClick={handleIsbnLookup}
                    disabled={isLookingUp}
                    className="shrink-0"
                  >
                    {isLookingUp ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      <Search className="h-4 w-4" />
                    )}
                    <span className="ml-2 hidden sm:inline">Lookup</span>
                  </Button>
                </div>
                {lookupError && (
                  <p className="text-sm text-destructive mt-1">{lookupError}</p>
                )}
                <p className="text-sm text-muted-foreground">
                  Enter ISBN and click Lookup to auto-fill book details
                </p>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="title"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Title *</FormLabel>
                <FormControl>
                  <Input placeholder="Enter book title" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <div className="space-y-4">
            <FormLabel>Authors *</FormLabel>
            {selectedAuthors.length > 0 && (
              <div className="flex flex-wrap gap-2">
                {selectedAuthors.map((author) => (
                  <Badge key={author.authorId} variant="secondary">
                    {author.name}
                    <button
                      type="button"
                      onClick={() => removeAuthor(author.authorId)}
                      className="ml-2 hover:text-destructive"
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </Badge>
                ))}
              </div>
            )}
            <div className="flex gap-2">
              <Popover open={open} onOpenChange={setOpen}>
                <PopoverTrigger asChild>
                  <Button
                    type="button"
                    variant="outline"
                    role="combobox"
                    aria-expanded={open}
                    className="flex-1 justify-between"
                  >
                    Select authors...
                    <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-[--radix-popover-trigger-width] p-0">
                  <Command>
                    <CommandInput placeholder="Search authors..." />
                    <CommandList>
                      <CommandEmpty>No author found.</CommandEmpty>
                      <CommandGroup>
                        {authors.map((author) => (
                          <CommandItem
                            key={author.authorId}
                            value={author.name}
                            onSelect={() => {
                              toggleAuthor(author);
                            }}
                          >
                            <Check
                              className={cn(
                                "mr-2 h-4 w-4",
                                selectedAuthors.find((a) => a.authorId === author.authorId)
                                  ? "opacity-100"
                                  : "opacity-0"
                              )}
                            />
                            {author.name}
                          </CommandItem>
                        ))}
                      </CommandGroup>
                    </CommandList>
                  </Command>
                </PopoverContent>
              </Popover>
              <Button
                type="button"
                variant="outline"
                size="icon"
                onClick={() => setShowAddAuthorDialog(true)}
                title="Add new author"
              >
                <Plus className="h-4 w-4" />
              </Button>
            </div>
          </div>

          <FormField
            control={form.control}
            name="goodreadsUrl"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Goodreads URL</FormLabel>
                <FormControl>
                  <Input placeholder="https://www.goodreads.com/book/show/..." {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <FormField
              control={form.control}
              name="year"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Publication Year</FormLabel>
                  <FormControl>
                    <Input
                      type="number"
                      placeholder="2024"
                      {...field}
                      onChange={(e) => {
                        const value = e.target.value;
                        field.onChange(value === "" ? null : parseInt(value));
                      }}
                      value={field.value ?? ""}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="pages"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Pages</FormLabel>
                  <FormControl>
                    <Input
                      type="number"
                      placeholder="300"
                      {...field}
                      onChange={(e) => {
                        const value = e.target.value;
                        field.onChange(value === "" ? null : parseInt(value));
                      }}
                      value={field.value ?? ""}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
          </div>

          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button
              type="button"
              variant="outline"
              onClick={() => router.back()}
              className="w-full sm:w-auto"
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isSubmitting} className="w-full sm:w-auto">
              {isSubmitting ? "Adding..." : "Add Book"}
            </Button>
          </div>
        </form>
      </Form>

      <Dialog open={showAddAuthorDialog} onOpenChange={setShowAddAuthorDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add New Author</DialogTitle>
            <DialogDescription>
              Create a new author to add to your collection
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <label htmlFor="author-name" className="text-sm font-medium">
                Name *
              </label>
              <Input
                id="author-name"
                placeholder="Author name"
                value={newAuthorName}
                onChange={(e) => setNewAuthorName(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <label htmlFor="author-bio" className="text-sm font-medium">
                Bio (optional)
              </label>
              <Input
                id="author-bio"
                placeholder="Brief biography"
                value={newAuthorBio}
                onChange={(e) => setNewAuthorBio(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                setShowAddAuthorDialog(false);
                setNewAuthorName("");
                setNewAuthorBio("");
              }}
            >
              Cancel
            </Button>
            <Button type="button" onClick={handleAddAuthor} disabled={isAddingAuthor}>
              {isAddingAuthor ? "Adding..." : "Add Author"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      </div>
    </div>
  );
}
