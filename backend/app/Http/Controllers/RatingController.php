<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Rating;
use App\Models\Comic;
use Illuminate\Support\Facades\Auth;

class RatingController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'comic_id' => 'required|exists:comics,id',
            'rating' => 'required|integer|min:1|max:5',
        ]);

        $rating = Rating::updateOrCreate(
            ['user_id' => Auth::id(), 'comic_id' => $validated['comic_id']],
            ['rating' => $validated['rating']]
        );

        // Hitung rata-rata rating terbaru untuk komik tersebut
        $averageRating = Rating::where('comic_id', $validated['comic_id'])->avg('rating');

        return response()->json([
            'message' => 'Rating berhasil disimpan',
            'data' => $rating,
            'average_rating' => round($averageRating, 1)
        ]);
    }

    public function getUserRating($comicId)
    {
        $rating = Rating::where('user_id', Auth::id())
            ->where('comic_id', $comicId)
            ->first();

        return response()->json(['rating' => $rating ? $rating->rating : 0]);
    }
}
