<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\Worker;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class StaffAccountController extends Controller
{
    // Create a Driver account
    public function createDriver(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:drivers,email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $driver = Driver::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        return response()->json([
            'message' => 'Driver account created successfully',
            'driver' => [
                'id' => $driver->id,
                'name' => $driver->name,
                'email' => $driver->email,
            ],
        ], 201);
    }

    // Create a Worker account
    public function createWorker(Request $request)
    {
        $validated = $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'worker_id' => 'required|string|max:255|unique:workers,worker_id',
            'mobile' => 'required|string|max:20',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $worker = Worker::create([
            'first_name' => $validated['first_name'],
            'last_name' => $validated['last_name'],
            'worker_id' => $validated['worker_id'],
            'mobile' => $validated['mobile'],
            'password' => Hash::make($validated['password']),
        ]);

        return response()->json([
            'message' => 'Worker account created successfully',
            'worker' => [
                'id' => $worker->id,
                'first_name' => $worker->first_name,
                'last_name' => $worker->last_name,
                'worker_id' => $worker->worker_id,
                'mobile' => $worker->mobile,
            ],
        ], 201);
    }

    // Get all Driver accounts
    public function drivers()
    {
        $drivers = Driver::select(
            'id',
            'name'
        )->orderBy('name')->get();

        return response()->json([
            'drivers' => $drivers,
        ], 200);
    }
}