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

        // Diarahkan ke route /foto/{path} (lihat routes/api.php), BUKAN ke
        // /storage/{path} (symlink). Alasannya: `php artisan serve` (PHP
        // built-in server) menolak (403 Forbidden) file yang diakses lewat
        // symbolic link, jadi jalur /storage/... tidak bisa diandalkan di
        // environment ini. Route /foto/{path} men-serve file yang sama
        // tapi lewat Laravel langsung, jadi tetap jalan di php artisan
        // serve maupun web server lain (Apache/Nginx/dll).
        //
        // Host-nya tetap diambil dari request yang sedang berjalan (bukan
        // APP_URL statis di .env), supaya otomatis benar walau URL ngrok
        // berubah tiap kali di-restart.
        $host = request()?->getSchemeAndHttpHost() ?? rtrim(config('app.url'), '/');

        return $host . '/api/foto/' . $this->foto_path;
    }
}
