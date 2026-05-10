<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Models\Panel;
use App\Models\Episode;
use Illuminate\Support\Facades\Storage;

class PanelController extends Controller
{
    public function index(Episode $episode)
    {
        return response()->json(['data' => $episode->panels()->orderBy('sort_order', 'asc')->get()]);
    }

    public function store(Request $request, Episode $episode)
    {
        $request->validate([
            'images' => 'required|array',
            'images.*' => 'image|mimes:jpg,jpeg,png|max:5120', // Max 5MB per image
        ]);

        $panels = [];
        $lastSortOrder = $episode->panels()->max('sort_order') ?? -1;

        foreach ($request->file('images') as $index => $image) {
            $path = $image->store('panels/' . $episode->id, 'public');
            $panels[] = Panel::create([
                'episode_id' => $episode->id,
                'image_path' => $path,
                'sort_order' => $lastSortOrder + $index + 1,
            ]);
        }

        return response()->json([
            'message' => 'Panels uploaded successfully',
            'data' => $panels
        ], 201);
    }

    public function destroy(Panel $panel)
    {
        if ($panel->image_path) {
            Storage::disk('public')->delete($panel->image_path);
        }
        $panel->delete();

        return response()->json(['message' => 'Panel deleted successfully']);
    }

    public function reorder(Request $request, Episode $episode)
    {
        $request->validate([
            'panel_ids' => 'required|array',
            'panel_ids.*' => 'exists:panels,id',
        ]);

        foreach ($request->panel_ids as $index => $id) {
            Panel::where('id', $id)->where('episode_id', $episode->id)->update(['sort_order' => $index]);
        }

        return response()->json(['message' => 'Panels reordered successfully']);
    }
}
