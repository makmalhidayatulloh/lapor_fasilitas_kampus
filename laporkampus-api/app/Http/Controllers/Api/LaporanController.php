<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\LaporanResource;
use App\Models\Laporan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class LaporanController extends Controller
{
    // GET /api/laporans
    // User biasa hanya melihat laporan miliknya sendiri.
    // Admin melihat semua laporan, bisa difilter ?status=pending|proses|selesai
    public function index(Request $request)
    {
        $query = Laporan::with(['kategori', 'user'])->latest();

        if (! $request->user()->isAdmin()) {
            $query->where('user_id', $request->user()->id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $laporans = $query->paginate(10);

        return LaporanResource::collection($laporans);
    }

    // POST /api/laporans
    // Membuat laporan baru + upload foto bukti + koordinat GPS otomatis
    public function store(Request $request)
    {
        $validated = $request->validate([
            'judul' => 'required|string|max:255',
            'deskripsi' => 'required|string',
            'kategori_id' => 'required|exists:kategoris,id',
            'lokasi_text' => 'nullable|string|max:255',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'foto' => 'required|image|mimes:jpg,jpeg,png|max:5120', // maks 5MB
        ]);

        // Simpan foto ke storage/app/public/laporan_foto
        $path = $request->file('foto')->store('laporan_foto', 'public');

        $laporan = Laporan::create([
            'user_id' => $request->user()->id,
            'kategori_id' => $validated['kategori_id'],
            'judul' => $validated['judul'],
            'deskripsi' => $validated['deskripsi'],
            'foto_path' => $path,
            'lokasi_text' => $validated['lokasi_text'] ?? null,
            'latitude' => $validated['latitude'] ?? null,
            'longitude' => $validated['longitude'] ?? null,
            'status' => 'pending',
        ]);

        $laporan->load(['kategori', 'user']);

        return new LaporanResource($laporan);
    }

    // GET /api/laporans/{id}
    public function show(Request $request, Laporan $laporan)
    {
        $this->authorizeAccess($request, $laporan);

        $laporan->load(['kategori', 'user']);

        return new LaporanResource($laporan);
    }

    // POST /api/laporans/{id}  (pakai method spoofing _method=PUT dari Flutter karena ada file upload)
    // Hanya pemilik laporan yang boleh edit, dan hanya selama status masih 'pending'
    public function update(Request $request, Laporan $laporan)
    {
        $this->authorizeAccess($request, $laporan);

        if ($request->user()->id !== $laporan->user_id) {
            return response()->json(['message' => 'Tidak diizinkan mengubah laporan ini'], 403);
        }

        if ($laporan->status !== 'pending') {
            return response()->json(['message' => 'Laporan yang sudah diproses tidak bisa diubah'], 422);
        }

        $validated = $request->validate([
            'judul' => 'sometimes|required|string|max:255',
            'deskripsi' => 'sometimes|required|string',
            'kategori_id' => 'sometimes|required|exists:kategoris,id',
            'lokasi_text' => 'nullable|string|max:255',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'foto' => 'nullable|image|mimes:jpg,jpeg,png|max:5120',
        ]);

        if ($request->hasFile('foto')) {
            if ($laporan->foto_path) {
                Storage::disk('public')->delete($laporan->foto_path);
            }
            $validated['foto_path'] = $request->file('foto')->store('laporan_foto', 'public');
        }

        $laporan->update($validated);
        $laporan->load(['kategori', 'user']);

        return new LaporanResource($laporan);
    }

    // PATCH /api/laporans/{id}/status
    // Khusus admin: mengubah status pending -> proses -> selesai
    public function updateStatus(Request $request, Laporan $laporan)
    {
        if (! $request->user()->isAdmin()) {
            return response()->json(['message' => 'Hanya admin yang bisa mengubah status'], 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:pending,proses,selesai',
            'catatan_admin' => 'nullable|string',
        ]);

        $laporan->update($validated);
        $laporan->load(['kategori', 'user']);

        return new LaporanResource($laporan);
    }

    // DELETE /api/laporans/{id}
    public function destroy(Request $request, Laporan $laporan)
    {
        if (! $request->user()->isAdmin() && $request->user()->id !== $laporan->user_id) {
            return response()->json(['message' => 'Tidak diizinkan menghapus laporan ini'], 403);
        }

        if ($laporan->foto_path) {
            Storage::disk('public')->delete($laporan->foto_path);
        }

        $laporan->delete();

        return response()->json(['message' => 'Laporan berhasil dihapus']);
    }

    private function authorizeAccess(Request $request, Laporan $laporan): void
    {
        abort_if(
            ! $request->user()->isAdmin() && $request->user()->id !== $laporan->user_id,
            403,
            'Tidak diizinkan mengakses laporan ini'
        );
    }
}
