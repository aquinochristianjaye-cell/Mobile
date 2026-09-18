<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Worker\WorkerController;
use App\Http\Controllers\Api\Worker\WorkerAuthController;
use App\Http\Controllers\Api\Worker\WorkerAssignmentController;

Route::get('/worker/test', [WorkerController::class, 'test']);

Route::post('/worker/login', [WorkerAuthController::class, 'login']);

Route::get(
    '/worker/{workerId}/assignments',
    [WorkerAssignmentController::class, 'index']
);

Route::get(
    '/worker/{workerId}/completed',
    [WorkerAssignmentController::class, 'completed']
);

Route::post(
    '/worker/assignments/{assignmentId}/start',
    [WorkerAssignmentController::class, 'start']
);

Route::post(
    '/worker/assignments/{assignmentId}/finish',
    [WorkerAssignmentController::class, 'finish']
);

