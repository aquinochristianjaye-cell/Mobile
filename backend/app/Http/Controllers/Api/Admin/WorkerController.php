<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Worker;

class WorkerController extends Controller
{
    public function index()
    {
        $workers = Worker::select(
            'id',
            'first_name',
            'last_name',
            'worker_id',
            'mobile',
            'is_available',
            'is_on_break'
        )->orderBy('first_name')->get();

        return response()->json([
            'workers' => $workers,
        ], 200);
    }
}