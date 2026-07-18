<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Kategori extends Model
{
    protected $fillable = ['nama'];

    public function laporans()
    {
        return $this->hasMany(Laporan::class);
    }
}
