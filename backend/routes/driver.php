<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Driver\DriverController;
use App\Http\Controllers\Api\Driver\DriverAuthController;
use App\Http\Controllers\Api\Driver\AppointmentController;

Route::get('/driver/test', [DriverController::class, 'test']);

Route::post('/driver/login', [DriverAuthController::class, 'login']);

Route::post('/driver/appointments', [AppointmentController::class, 'store']);

Route::post('/driver/check-in', [AppointmentController::class, 'checkIn']);

Route::get(
    '/driver/{driverId}/appointments/{appointmentId}',
    [AppointmentController::class, 'status']
);

Route::get(
    '/driver/{driverId}/completed',
    [AppointmentController::class, 'completed']
);