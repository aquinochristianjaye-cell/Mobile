<?php

namespace App\Http\Controllers\Api\Worker;

use App\Http\Controllers\Controller;
use App\Models\Worker;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class WorkerAuthController extends Controller
{
    public function register(Request $request)
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
            'message' => 'Worker registered successfully',
            'worker' => [
                'id' => $worker->id,
                'first_name' => $worker->first_name,
                'last_name' => $worker->last_name,
                'worker_id' => $worker->worker_id,
                'mobile' => $worker->mobile,
            ],
        ], 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'worker_id' => 'required|string',
            'password' => 'required|string',
        ]);

        $worker = Worker::where(
            'worker_id',
            $validated['worker_id']
        )->first();

        if (
            !$worker ||
            !Hash::check(
                $validated['password'],
                $worker->password
            )
        ) {
            return response()->json([
                'message' => 'Invalid Worker ID or password'
            ], 401);
        }

        return response()->json([
            'message' => 'Login successful',
            'worker' => [
                'id' => $worker->id,
                'first_name' => $worker->first_name,
                'last_name' => $worker->last_name,
                'worker_id' => $worker->worker_id,
                'mobile' => $worker->mobile,
            ],
        ], 200);
    }
}