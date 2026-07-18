<?php

namespace Database\Seeders;

use App\Models\Kategori;
use Illuminate\Database\Seeder;

class KategoriSeeder extends Seeder
{
    public function run(): void
    {
        $data = ['Listrik', 'AC / Pendingin Ruangan', 'Sanitasi & Air', 'Furnitur', 'Jaringan Internet', 'Bangunan / Struktur', 'Lainnya'];

        foreach ($data as $nama) {
            Kategori::firstOrCreate(['nama' => $nama]);
        }
    }
}
