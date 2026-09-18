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
    Schema::table('worker_assignments', function (Blueprint $table) {
        $table->unsignedTinyInteger('wash_bay_id')
            ->nullable()
            ->after('worker_id');
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
{
    Schema::table('worker_assignments', function (Blueprint $table) {
        $table->dropColumn('wash_bay_id');
    });
}
};
