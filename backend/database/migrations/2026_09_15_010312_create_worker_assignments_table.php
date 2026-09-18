<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
  public function up(): void
{
    Schema::create('worker_assignments', function (Blueprint $table) {
        $table->id();

        $table->foreignId('worker_id')
            ->constrained('workers')
            ->onDelete('cascade');

        $table->foreignId('appointment_id')
            ->constrained('appointments')
            ->onDelete('cascade');

        $table->string('status')->default('assigned');

        $table->timestamps();

        $table->unique(['worker_id', 'appointment_id']);
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('worker_assignments');
    }
};
