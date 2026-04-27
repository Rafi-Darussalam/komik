<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Models\Comic;

class ComicController extends Controller
{
    public function index()
    {
        $comics = Comic::with('episodes')->get();
        return response()->json(['data' => $comics]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'author' => 'nullable|string|max:255',
            'synopsis' => 'nullable|string',
            'cover_url' => 'nullable|string|url',
        ]);

        $comic = Comic::create($validated);

        return response()->json(['message' => 'Comic created successfully', 'data' => $comic], 201);
    }

    public function show(Comic $comic)
    {
        return response()->json(['data' => $comic->load('episodes')]);
    }

    public function update(Request $request, Comic $comic)
    {
        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'author' => 'nullable|string|max:255',
            'synopsis' => 'nullable|string',
            'cover_url' => 'nullable|string|url',
        ]);

        $comic->update($validated);

        return response()->json(['message' => 'Comic updated successfully', 'data' => $comic]);
    }

    public function destroy(Comic $comic)
    {
        $comic->delete();

        return response()->json(['message' => 'Comic deleted successfully']);
    }
}
