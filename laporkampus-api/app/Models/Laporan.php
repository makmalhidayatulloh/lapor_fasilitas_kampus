<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Laporan extends Model
{
    protected $fillable = [
        'user_id',
        'kategori_id',
        'judul',
        'deskripsi',
        'foto_path',
        'lokasi_text',
        'latitude',
        'longitude',
        'status',
        'catatan_admin',
    ];

    protected $appends = ['foto_url'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function kategori()
    {
        return $this->belongsTo(Kategori::class);
    }

    // URL publik lengkap ke foto, dipakai Flutter untuk menampilkan gambar
    public function getFotoUrlAttribute(): ?string
    {
        return $this->foto_path ? Storage::disk('public')->url($this->foto_path) : null;
    }
}
