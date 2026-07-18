<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LaporanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'judul' => $this->judul,
            'deskripsi' => $this->deskripsi,
            'foto_url' => $this->foto_url,
            'lokasi_text' => $this->lokasi_text,
            'latitude' => $this->latitude ? (float) $this->latitude : null,
            'longitude' => $this->longitude ? (float) $this->longitude : null,
            'status' => $this->status,
            'catatan_admin' => $this->catatan_admin,
            'kategori' => [
                'id' => $this->kategori->id,
                'nama' => $this->kategori->nama,
            ],
            'pelapor' => [
                'id' => $this->user->id,
                'nama' => $this->user->name,
            ],
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}
