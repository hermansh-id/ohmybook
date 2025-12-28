# 📚 Bookjet

A modern, feature-rich book tracking and reading management application built with Next.js 16, React 19, and TypeScript.

## ✨ Features

### 📖 Book Management
- **Library Management**: Add, edit, and organize your book collection
- **Goodreads Integration**: Import book data directly from Goodreads URLs
- **Search & Filter**: Quickly find books in your library
- **Book Details**: Track ISBN, authors, genres, pages, publication year, and cover images
- **Series Support**: Organize books into series

### 📊 Reading Tracking
- **Multiple Reading Statuses**: Want to Read, Currently Reading, Finished, Did Not Finish, On Hold
- **Progress Tracking**: Monitor your reading progress with current page tracking
- **Reading Sessions**: Log individual reading sessions with pages read, time spent, and notes
- **Ratings & Reviews**: Rate and review finished books
- **Start/Finish Dates**: Automatically track when you started and finished each book

### 📈 Dashboard
- **Reading Statistics Overview**: Get a comprehensive view of your reading habits
- **Reading Goal Tracker**: Set and track annual reading goals with progress visualization
- **Library Completion**: Track what percentage of your library you've read with estimated completion time
- **Currently Reading**: View all books in progress with progress bars
- **Recent Finished Books**: Quick access to your recently completed reads
- **Reading History Chart**: Visualize your reading activity over the past 12 months
- **Quick Stats Cards**: Books read, pages read, reading time, and more at a glance

### 📅 Calendar View
- **Reading Calendar**: Visualize books finished by date
- **Monthly/Yearly Views**: Track your reading patterns over time

### 🎨 Monthly Recap
- **Monthly Reading Summary**: Generate beautiful monthly reading recaps
- **Shareable Instagram Stories**: Export recap as Instagram Story-sized images (1080x1920px)
- **iPhone-Inspired Design**: Modern glassmorphism design with iOS color palette
- **Comprehensive Stats**: Books finished, pages read, top genre, top rated book, fastest read, favorite author

### 📊 Statistics Page
- **Library Overview**:
  - Total books in library
  - Number of unique authors
  - Number of unique genres
  - Total pages across all books
  - Average pages per book
- **Reading Analytics**:
  - Books read (all-time, this year, this month)
  - Pages read (all-time, this year, this month)
  - Average rating
  - Total reading time
  - Currently reading count
  - Want to read count
  - Average pages per day
- **Top Authors & Genres**: See which authors and genres you read most

### ⚙️ Settings & Customization
- **Dark Mode**: Beautiful dark theme support
- **Reading Goals**: Customize your annual reading targets
- **Theme Switching**: Seamless theme toggling

### 🔐 Authentication
- **Secure Login**: Email/password authentication powered by Better Auth
- **Protected Routes**: Secure access to your personal reading data

## 🛠️ Tech Stack

- **Framework**: Next.js 16.1 with App Router
- **UI Library**: React 19.2
- **Language**: TypeScript 5
- **Styling**: Tailwind CSS v4
- **Database**: Neon PostgreSQL (serverless)
- **ORM**: Drizzle ORM
- **Authentication**: Better Auth
- **Data Fetching**: TanStack Query (React Query)
- **UI Components**: shadcn/ui (new-york style)
- **Icons**: Lucide React
- **Charts**: Recharts
- **Image Generation**: html-to-image
- **Package Manager**: Bun

## 📦 Installation

### Prerequisites

- **Bun**: Install from [bun.sh](https://bun.sh)
- **PostgreSQL Database**: Get a free database from [Neon](https://neon.tech)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bookjet
   ```

2. **Install dependencies**
   ```bash
   bun install
   ```

3. **Set up environment variables**

   Create a `.env.local` file in the root directory:
   ```env
   # Database
   DATABASE_URL=your_neon_postgres_connection_string

   # Better Auth
   BETTER_AUTH_SECRET=your_random_secret_key
   BETTER_AUTH_URL=http://localhost:3000
   ```

4. **Initialize the database**
   ```bash
   # Push schema to database
   bun db:push

   # Or generate and run migrations
   bun db:generate
   bun db:migrate
   ```

5. **Run the development server**
   ```bash
   bun dev
   ```

6. **Open your browser**

   Navigate to [http://localhost:3000](http://localhost:3000)

## 🚀 Available Scripts

- `bun dev` - Start development server at http://localhost:3000
- `bun build` - Build for production
- `bun start` - Start production server
- `bun lint` - Run ESLint
- `bun db:push` - Push schema changes to database
- `bun db:generate` - Generate database migrations
- `bun db:migrate` - Run database migrations
- `bun db:studio` - Open Drizzle Studio (database GUI)

## 📁 Project Structure

```
bookjet/
├── app/                    # Next.js App Router pages
│   ├── dashboard/          # Dashboard and main app pages
│   │   ├── books/          # Books management
│   │   ├── calendar/       # Calendar view
│   │   ├── statistics/     # Statistics page
│   │   └── settings/       # Settings page
│   ├── actions/            # Server actions
│   ├── api/                # API routes
│   └── layout.tsx          # Root layout
├── components/             # React components
│   ├── ui/                 # shadcn/ui components
│   └── ...                 # Custom components
├── lib/                    # Utility functions
│   ├── db/                 # Database configuration
│   │   ├── schema/         # Database schema
│   │   └── queries.ts      # Database queries
│   ├── auth.ts             # Authentication setup
│   └── utils.ts            # Helper functions
└── public/                 # Static assets
```

## 🎯 Usage Guide

### Adding Your First Book

1. Navigate to the Books page
2. Click "Add Book" button
3. Either:
   - Paste a Goodreads URL to auto-import book data
   - Manually enter book details
4. Add the book to your reading log with a status

### Setting a Reading Goal

1. Go to Settings
2. Set your target number of books for the year
3. Track progress on the Dashboard

### Logging Reading Sessions

1. From the Dashboard, click "Log Session"
2. Select a book from your "Currently Reading" list
3. Enter pages read, time spent, and optional notes
4. Session is saved and progress is updated

### Generating Monthly Recap

1. On the Dashboard, click "Monthly Recap"
2. Select the month and year
3. View your reading statistics
4. Click "Share" to download as an Instagram Story image

## 🎨 Design Philosophy

- **Mobile-First**: Responsive design optimized for all screen sizes
- **Modern UI**: Clean, minimalist interface with smooth animations
- **Dark Mode**: Full dark mode support for comfortable reading
- **Accessibility**: Built with accessibility best practices

## 🔒 Privacy & Security

- All data is stored securely in your PostgreSQL database
- Passwords are hashed using Better Auth
- Protected routes ensure only you can access your data
- No third-party tracking or analytics

## 📝 License

This project is private and for personal use.

## 🤝 Contributing

This is a personal project, but suggestions and bug reports are welcome!

## 🙏 Acknowledgments

- Built with [Next.js](https://nextjs.org)
- UI components from [shadcn/ui](https://ui.shadcn.com)
- Icons from [Lucide](https://lucide.dev)
- Database hosted on [Neon](https://neon.tech)
- Fonts: [Geist Sans & Geist Mono](https://vercel.com/font)

---

**Version**: 1.0.0

Made with ❤️ for book lovers
