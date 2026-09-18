<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\StationSupply;

class StationSupplySeeder extends Seeder
{
    public function run(): void
    {
        StationSupply::updateOrCreate(
            ['name' => 'Foam Wash'],
            ['level' => 78]
        );

        StationSupply::updateOrCreate(
            ['name' => 'Disinfectant'],
            ['level' => 64]
        );

        StationSupply::updateOrCreate(
            ['name' => 'Water'],
            ['level' => 31]
        );
    }
}