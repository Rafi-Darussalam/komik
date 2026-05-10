<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Models\Comic;

class ComicController extends Controller
{
    public function index(Request $request)
    {
        $query = Comic::query();

        // Check if user is admin via Sanctum (optional check)
        $user = auth('sanctum')->user();
        
        if (!$user || $user->role !== 'admin') {
            $query->where('status', 'public');
        }

        $comics = $query->with('episodes')
            ->withCount('ratings')
            ->withAvg('ratings', 'rating')
            ->withCount(['histories as histories_count' => function ($query) {
                $query->select(\Illuminate\Support\Facades\DB::raw('count(distinct(user_id))'));
            }])
            ->get();
        return response()->json(['data' => $comics]);
    }

    public function store(Request $request)
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
            $validated['cover_url'] = 'comics/' . basename($path);
        }

        if (!isset($validated['status'])) {
            $validated['status'] = 'private';
        }

        $comic = Comic::create($validated);

        return response()->json(['message' => 'Comic created successfully', 'data' => $comic], 201);
    }

    public function show(Comic $comic)
    {
        $user = auth('sanctum')->user();
        
        if ($comic->status === 'private' && (!$user || $user->role !== 'admin')) {
            return response()->json(['message' => 'Comic is private'], 403);
        }

        $comic->load('episodes');
        $comic->loadCount('ratings');
        $comic->loadAvg('ratings', 'rating');
        $comic->loadCount(['histories as histories_count' => function ($query) {
            $query->select(\Illuminate\Support\Facades\DB::raw('count(distinct(user_id))'));
        }]);
        return response()->json(['data' => $comic]);
    }

    public function update(Request $request, Comic $comic)
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
            $validated['cover_url'] = 'comics/' . basename($path);
        }

        $comic->update($validated);

        return response()->json(['message' => 'Comic updated successfully', 'data' => $comic]);
    }

    public function destroy(Comic $comic)
    {
        $comic->delete();

        return response()->json(['message' => 'Comic deleted successfully']);
    }
}
