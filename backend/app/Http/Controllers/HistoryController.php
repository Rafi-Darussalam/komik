<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Models\History;
use Illuminate\Support\Facades\Auth;

class HistoryController extends Controller
{
    public function index()
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        $histories = $user->histories()->with('comic')->get();
        return response()->json(['data' => $histories]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'comic_id' => 'required|exists:comics,id',
            'last_chapter_read' => 'required|integer|min:1',
        ]);

        $history = History::updateOrCreate(
            ['user_id' => Auth::id(), 'comic_id' => $validated['comic_id']],
            ['last_chapter_read' => $validated['last_chapter_read']]
        );

        return response()->json(['message' => 'History updated successfully', 'data' => $history]);
    }

    public function destroy(History $history)
    {
        if ($history->user_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $history->delete();

        return response()->json(['message' => 'History deleted successfully']);
    }
}
