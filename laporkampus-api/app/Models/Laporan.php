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
        if (! $this->foto_path) {
            return null;
        }

        $host = request()?->getSchemeAndHttpHost() ?? rtrim(config('app.url'), '/');

        // Paksa https, karena ngrok selalu publik lewat https meski request
        // internal ke Laravel kadang terbaca sebagai http.
        $host = preg_replace('/^http:/', 'https:', $host);

        return $host . '/api/foto/' . $this->foto_path;
    }
}
