<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('laporans', function (Blueprint $table) {
            $table->id();

            // Relasi
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('kategori_id')->constrained('kategoris');

            // Data laporan
            $table->string('judul');
            $table->text('deskripsi');
            $table->string('foto_path'); // path file di storage
            $table->string('lokasi_text')->nullable(); // nama lokasi manual, misal "Gedung A Lt. 2"

            // GPS otomatis saat foto diambil
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();

            // Status perbaikan
            $table->enum('status', ['pending', 'proses', 'selesai'])->default('pending');
            $table->text('catatan_admin')->nullable(); // catatan/alasan dari admin saat update status

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('laporans');
    }
};
