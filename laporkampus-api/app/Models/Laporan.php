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

        // Storage::disk('public')->url() membangun URL memakai APP_URL di .env
        // (mis. "http://localhost/storage/xxx.jpg"). Masalahnya, "localhost"
        // itu valid buat browser di laptop kamu, tapi TIDAK valid untuk HP
        // fisik yang mengakses API lewat tunnel ngrok — di HP, "localhost"
        // artinya HP itu sendiri, bukan laptop kamu. Makanya foto gagal
        // dimuat walau data lain (judul, deskripsi, dst) tetap tampil normal.
        //
        // Solusinya: ambil path relatifnya saja ("/storage/xxx.jpg"), lalu
        // tempelkan ke host yang BENAR-BENAR sedang dipakai untuk mengakses
        // API saat itu (otomatis terbaca dari request masuk, jadi tetap
        // benar walau URL ngrok berubah setiap kali kamu restart ngrok,
        // tanpa perlu edit APP_URL manual tiap saat).
        $path = parse_url(Storage::disk('public')->url($this->foto_path), PHP_URL_PATH);
        $host = request()?->getSchemeAndHttpHost() ?? rtrim(config('app.url'), '/');

        return $host . $path;
    }
}
