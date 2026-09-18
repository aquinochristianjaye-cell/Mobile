<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
{
    Schema::table('appointments', function (Blueprint $table) {
        $table->string('status')->default('scheduled')->after('id');
        $table->timestamp('arrived_at')->nullable()->after('status');
    });
}

public function down(): void
{
    Schema::table('appointments', function (Blueprint $table) {
        $table->dropColumn([
            'status',
            'arrived_at',
        ]);
    });
}
};
