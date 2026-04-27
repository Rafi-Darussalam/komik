<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ComicController;
use App\Http\Controllers\HistoryController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/comics', [ComicController::class, 'index']);
Route::get('/comics/{comic}', [ComicController::class, 'show']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    
    Route::post('/logout', [AuthController::class, 'logout']);

    // Admin/Dashboard routes (ideally protected by admin middleware, but for now just auth)
    Route::post('/comics', [ComicController::class, 'store']);
    Route::put('/comics/{comic}', [ComicController::class, 'update']);
    Route::delete('/comics/{comic}', [ComicController::class, 'destroy']);

    // History routes
    Route::get('/histories', [HistoryController::class, 'index']);
    Route::post('/histories', [HistoryController::class, 'store']);
    Route::delete('/histories/{history}', [HistoryController::class, 'destroy']);
});
