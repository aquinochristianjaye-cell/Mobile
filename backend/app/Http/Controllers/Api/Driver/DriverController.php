<?php

namespace App\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;

class DriverController extends Controller
{
    public function test()
    {
        return response()->json([
            'message' => 'Driver Controller is working'
        ]);
    }
}