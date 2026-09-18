<?php

namespace App\Http\Controllers\Api\Worker;

use App\Http\Controllers\Controller;

class WorkerController extends Controller
{
    public function test()
    {
        return response()->json([
            'message' => 'Worker Controller is working'
        ]);
    }
}