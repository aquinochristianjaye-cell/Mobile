<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Admin\AdminController;
use App\Http\Controllers\Api\Admin\AdminAuthController;
use App\Http\Controllers\Api\Admin\NotificationController;
use App\Http\Controllers\Api\Admin\AppointmentController;
use App\Http\Controllers\Api\Admin\WorkerAssignmentController;
use App\Http\Controllers\Api\Admin\WorkerController;
use App\Http\Controllers\Api\Admin\StaffAccountController;


Route::get('/admin/test', [AdminController::class, 'test']);

Route::post('/register', [AdminAuthController::class, 'register']);

Route::post('/login', [AdminAuthController::class, 'login']);

Route::get('/admin/notifications', [NotificationController::class, 'index']);

Route::get('/admin/appointments', [AppointmentController::class, 'index']);

Route::post('/admin/deploy', [WorkerAssignmentController::class, 'deploy']);

Route::get('/admin/workers', [WorkerController::class, 'index']);

Route::get('/admin/assignments/active', [WorkerAssignmentController::class, 'active']);

Route::get('/admin/assignments/active', [WorkerAssignmentController::class, 'active']);

Route::get(
    '/admin/assignments/completed',
    [WorkerAssignmentController::class, 'completed']
);

Route::post(
    '/admin/drivers',
    [StaffAccountController::class, 'createDriver']
);

Route::get(
    '/admin/drivers',
    [StaffAccountController::class, 'drivers']
);

Route::post(
    '/admin/workers',
    [StaffAccountController::class, 'createWorker']
);


