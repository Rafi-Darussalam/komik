<?php

namespace App\Http\Controllers;

use App\Models\AppNotification;
use Illuminate\Http\Request;
use Carbon\Carbon;

class NotificationController extends Controller
{
    // Fetch notifications for frontend (User)
    public function index(Request $request)
    {
        $now = Carbon::now();
        $user = $request->user();
        
        $query = AppNotification::where(function($q) use ($now) {
                $q->whereNull('expires_at')
                  ->orWhere('expires_at', '>', $now);
            });

        // Jika user login, ambil notifikasi global (null) dan notifikasi miliknya
        if ($user) {
            $query->where(function($q) use ($user) {
                $q->whereNull('user_id')
                  ->orWhere('user_id', $user->id);
            });
        } else {
            // Jika guest, hanya ambil notifikasi global
            $query->whereNull('user_id');
        }

        $notifications = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $notifications
        ]);
    }

    // Admin fetch all notifications (include expired)
    public function adminIndex(Request $request)
    {
        $notifications = AppNotification::orderBy('created_at', 'desc')->get();
        return response()->json([
            'status' => 'success',
            'data' => $notifications
        ]);
    }

    // Admin create notification
    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'user_id' => 'nullable|exists:users,id',
            'expires_in_hours' => 'nullable|numeric|min:0.5'
        ]);

        $expiresAt = null;
        if ($request->filled('expires_in_hours')) {
            $expiresAt = Carbon::now()->addHours((float) $request->expires_in_hours);
        }

        $notification = AppNotification::create([
            'title' => $request->title,
            'message' => $request->message,
            'user_id' => $request->user_id,
            'expires_at' => $expiresAt,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Notifikasi berhasil dibuat',
            'data' => $notification
        ], 201);
    }

    // Admin delete notification
    public function destroy($id)
    {
        $notification = AppNotification::findOrFail($id);
        $notification->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Notifikasi berhasil dihapus'
        ]);
    }
}
