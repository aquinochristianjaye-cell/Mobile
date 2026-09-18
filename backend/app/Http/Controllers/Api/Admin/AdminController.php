<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;

class AdminController extends Controller
{
    public function test()
    {
        return response()->json([
            'message' => 'Admin Controller is working'
        ]);
    }
}