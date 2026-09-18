<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\StationSupplyController;

require __DIR__.'/admin.php';
require __DIR__.'/driver.php';
require __DIR__.'/worker.php';

Route::get('/supplies', [StationSupplyController::class, 'index']);

Route::put(
    '/worker/supplies',
    [StationSupplyController::class, 'update']
);