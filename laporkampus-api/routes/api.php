<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\KategoriController;
use App\Http\Controllers\Api\LaporanController;
use Illuminate\Support\Facades\Route;

// ==== PUBLIC ROUTES ====
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// ==== PROTECTED ROUTES (butuh token Sanctum) ====
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    Route::get('/kategoris', [KategoriController::class, 'index']);

    Route::get('/laporans', [LaporanController::class, 'index']);
    Route::post('/laporans', [LaporanController::class, 'store']);
    Route::get('/laporans/{laporan}', [LaporanController::class, 'show']);
    Route::post('/laporans/{laporan}', [LaporanController::class, 'update']); // pakai _method=PUT dari Flutter
    Route::patch('/laporans/{laporan}/status', [LaporanController::class, 'updateStatus']); // khusus admin
    Route::delete('/laporans/{laporan}', [LaporanController::class, 'destroy']);
});
