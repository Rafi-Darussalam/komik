<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ComicController;
use App\Http\Controllers\HistoryController;
use App\Http\Controllers\RatingController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\PanelController;
use App\Http\Controllers\NotificationController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/comics', [ComicController::class, 'index']);
Route::get('/comics/{comic}', [ComicController::class, 'show']);
Route::get('/episodes/{episode}', function (App\Models\Episode $episode) {
    return response()->json(['data' => $episode->load('panels')]);
});


Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::get('/notifications', [NotificationController::class, 'index']);

    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/user/profile-photo', [AuthController::class, 'updateProfilePhoto']);

    Route::post('/comics', [ComicController::class, 'store']);
    Route::put('/comics/{comic}', [ComicController::class, 'update']);
    Route::delete('/comics/{comic}', [ComicController::class, 'destroy']);

    Route::get('/histories', [HistoryController::class, 'index']);
    Route::post('/histories', [HistoryController::class, 'store']);
    Route::delete('/histories/{history}', [HistoryController::class, 'destroy']);

    Route::post('/ratings', [RatingController::class, 'store']);
    Route::get('/ratings/{comicId}', [RatingController::class, 'getUserRating']);

    Route::get('/bookmarks', [\App\Http\Controllers\BookmarkController::class, 'index']);
    Route::get('/bookmarks/check/{comicId}', [\App\Http\Controllers\BookmarkController::class, 'check']);
    Route::post('/bookmarks/toggle/{comicId}', [\App\Http\Controllers\BookmarkController::class, 'toggle']);


    Route::middleware('admin')->prefix('admin')->group(function () {
        Route::get('/dashboard', [AdminController::class, 'dashboard']);

        Route::get('/users', [AdminController::class, 'indexUsers']);
        Route::post('/users', [AdminController::class, 'storeUser']);
        Route::put('/users/{user}', [AdminController::class, 'updateUser']);
        Route::delete('/users/{user}', [AdminController::class, 'destroyUser']);

        Route::get('/comics', [AdminController::class, 'indexComics']);
        Route::post('/comics', [AdminController::class, 'storeComic']);
        Route::put('/comics/{comic}', [AdminController::class, 'updateComic']);
        Route::delete('/comics/{comic}', [AdminController::class, 'destroyComic']);

        Route::get('/comics/{comic}/episodes', [AdminController::class, 'indexEpisodes']);
        Route::post('/comics/{comic}/episodes', [AdminController::class, 'storeEpisode']);
        Route::put('/episodes/{episode}', [AdminController::class, 'updateEpisode']);
        Route::delete('/episodes/{episode}', [AdminController::class, 'destroyEpisode']);

        Route::get('/episodes/{episode}/panels', [PanelController::class, 'index']);
        Route::post('/episodes/{episode}/panels', [PanelController::class, 'store']);
        Route::delete('/panels/{panel}', [PanelController::class, 'destroy']);
        Route::put('/episodes/{episode}/panels/reorder', [PanelController::class, 'reorder']);

        Route::get('/notifications', [NotificationController::class, 'adminIndex']);
        Route::post('/notifications', [NotificationController::class, 'store']);
        Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
    });

});

Route::get('/images/{path}', function ($path) {
    $fullPath = storage_path('app/public/' . $path);
    if (!file_exists($fullPath)) abort(404);
    return response()->file($fullPath, [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET',
    ]);
})->where('path', '.*');
