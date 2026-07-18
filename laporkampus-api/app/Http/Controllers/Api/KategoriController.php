<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kategori;

class KategoriController extends Controller
{
    // GET /api/kategoris
    public function index()
    {
        return response()->json(Kategori::orderBy('nama')->get());
    }
}
