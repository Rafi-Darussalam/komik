<?php

namespace App\Http\Controllers;

use App\Models\Bookmark;
use App\Models\Comic;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class BookmarkController extends Controller
{
    /**
     * Get all comics bookmarked by the authenticated user.
     */
    public function index()
    {
        $user = Auth::user();
        
        // Eager load the comic with its latest episode for the UI
        $bookmarks = Bookmark::where('user_id', $user->id)
            ->with(['comic' => function($query) {
                $query->with(['episodes' => function($q) {
                    $q->orderBy('chapter_number', 'desc')->take(1);
                }]);
            }])
            ->orderBy('created_at', 'desc')
            ->get();

        // Format to match the comic listing format on the frontend
        $formattedComics = $bookmarks->map(function ($bookmark) {
            $comic = $bookmark->comic;
            if (!$comic) return null;
            
            $latestEpisode = $comic->episodes->first();
            
            return [
                'id' => $comic->id,
                'title' => $comic->title,
                'author' => $comic->author,
                'cover_url' => $comic->cover_url,
                'latest_chapter' => $latestEpisode ? "Ch. {$latestEpisode->chapter_number}" : "-",
                'latest_chapter_title' => $latestEpisode ? $latestEpisode->title : "",
                'status' => $comic->status,
                'bookmark_id' => $bookmark->id,
                'bookmarked_at' => $bookmark->created_at,
            ];
        })->filter()->values();

        return response()->json([
            'status' => 'success',
            'data' => $formattedComics
        ]);
    }

    /**
     * Toggle bookmark status for a comic.
     */
    public function toggle($comicId)
    {
        $user = Auth::user();
        
        $comic = Comic::find($comicId);
        if (!$comic) {
            return response()->json([
                'status' => 'error',
                'message' => 'Comic not found'
            ], 404);
        }

        $bookmark = Bookmark::where('user_id', $user->id)
            ->where('comic_id', $comic->id)
            ->first();

        if ($bookmark) {
            // Already bookmarked, so remove it
            $bookmark->delete();
            return response()->json([
                'status' => 'success',
                'message' => 'Bookmark removed',
                'is_bookmarked' => false
            ]);
        } else {
            // Not bookmarked, so add it
            Bookmark::create([
                'user_id' => $user->id,
                'comic_id' => $comic->id
            ]);
            return response()->json([
                'status' => 'success',
                'message' => 'Bookmark added',
                'is_bookmarked' => true
            ]);
        }
    }

    /**
     * Check if a specific comic is bookmarked by the user.
     */
    public function check($comicId)
    {
        $user = Auth::user();
        
        $isBookmarked = Bookmark::where('user_id', $user->id)
            ->where('comic_id', $comicId)
            ->exists();

        return response()->json([
            'status' => 'success',
            'is_bookmarked' => $isBookmarked
        ]);
    }
}
