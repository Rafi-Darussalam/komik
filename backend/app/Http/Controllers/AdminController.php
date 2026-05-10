<?php

namespace App\Http\Controllers;

use App\Models\Comic;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AdminController extends Controller
{
    public function dashboard()
    {
        // Stats Role
        $totalUsers = User::where('role', 'user')->count();
        $totalAdmins = User::where('role', 'admin')->count();
        
        // Stats Comic Status
        $comicStats = Comic::get(['status'])
            ->groupBy('status')
            ->map(function ($items, $status) {
                return [
                    'status' => $status,
                    'total' => $items->count(),
                ];
            })
            ->values();

        // Recent items
        $recentUsers = User::orderBy('created_at', 'desc')->take(5)->get();
        $recentComics = Comic::orderBy('created_at', 'desc')->take(5)->get();

        return response()->json([
            'total_users' => $totalUsers,
            'total_admins' => $totalAdmins,
            'total_comics' => Comic::count(),
            'comic_stats' => $comicStats,
            'recent_users' => $recentUsers,
            'recent_comics' => $recentComics,
        ]);
    }

    public function indexUsers()
    {
        $users = User::orderBy('created_at', 'desc')->get();
        return response()->json(['data' => $users]);
    }

    public function storeUser(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'role' => ['required', Rule::in(['user', 'admin'])],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'],
        ]);

        return response()->json(['message' => 'User created successfully', 'data' => $user], 201);
    }

    public function updateUser(Request $request, User $user)
    {
        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => ['sometimes', 'required', 'string', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            'password' => 'nullable|string|min:8',
            'role' => ['sometimes', 'required', Rule::in(['user', 'admin'])],
        ]);

        if (isset($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        } else {
            unset($validated['password']);
        }

        $user->update($validated);

        return response()->json(['message' => 'User updated successfully', 'data' => $user->fresh()]);
    }

    public function destroyUser(User $user)
    {
        $user->delete();
        return response()->json(['message' => 'User deleted successfully']);
    }

    public function indexComics()
    {
        $comics = Comic::withCount(['episodes', 'ratings'])
            ->withAvg('ratings', 'rating')
            ->orderBy('created_at', 'desc')
            ->get();
        return response()->json(['data' => $comics]);
    }

    public function storeComic(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'author' => 'nullable|string|max:255',
            'synopsis' => 'nullable|string',
            'cover_image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'status' => 'nullable|string|in:private,public',
        ]);

        if ($request->hasFile('cover_image')) {
            $path = $request->file('cover_image')->store('comics', 'public');
            $validated['cover_url'] = $path;
        }

        if (!isset($validated['status'])) {
            $validated['status'] = 'private';
        }

        $comic = Comic::create($validated);
        return response()->json(['message' => 'Comic created successfully', 'data' => $comic], 201);
    }

    public function updateComic(Request $request, Comic $comic)
    {
        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'author' => 'nullable|string|max:255',
            'synopsis' => 'nullable|string',
            'cover_image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'status' => 'nullable|string|in:private,public',
        ]);

        if ($request->hasFile('cover_image')) {
            $path = $request->file('cover_image')->store('comics', 'public');
            $validated['cover_url'] = $path;
        }

        $comic->update($validated);
        return response()->json(['message' => 'Comic updated successfully', 'data' => $comic->fresh()]);
    }

    public function destroyComic(Comic $comic)
    {
        if ($comic->getRawOriginal('cover_url')) {
            \Illuminate\Support\Facades\Storage::disk('public')->delete($comic->getRawOriginal('cover_url'));
        }
        $comic->delete();
        return response()->json(['message' => 'Comic deleted successfully']);
    }

    // Episode Management
    public function indexEpisodes(Comic $comic)
    {
        return response()->json(['data' => $comic->episodes()->orderBy('chapter_number', 'asc')->get()]);
    }

    public function storeEpisode(Request $request, Comic $comic)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'chapter_number' => 'required|numeric',
        ]);

        $episode = $comic->episodes()->create($validated);
        return response()->json(['message' => 'Episode created successfully', 'data' => $episode], 201);
    }

    public function updateEpisode(Request $request, \App\Models\Episode $episode)
    {
        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'chapter_number' => 'sometimes|required|numeric',
        ]);

        $episode->update($validated);
        return response()->json(['message' => 'Episode updated successfully', 'data' => $episode->fresh()]);
    }

    public function destroyEpisode(\App\Models\Episode $episode)
    {
        $episode->delete();
        return response()->json(['message' => 'Episode deleted successfully']);
    }
}
