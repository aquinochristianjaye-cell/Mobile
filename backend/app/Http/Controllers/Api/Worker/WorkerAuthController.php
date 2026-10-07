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
            'must_change_password' => false,
        ]);

        return response()->json([
            'message' => 'Worker registered successfully',
            'worker' => [
                'id' => $worker->id,
                'first_name' => $worker->first_name,
                'last_name' => $worker->last_name,
                'worker_id' => $worker->worker_id,
                'mobile' => $worker->mobile,
                'must_change_password' => $worker->must_change_password,
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
                'message' => 'Invalid Worker ID or password',
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
                'must_change_password' => $worker->must_change_password,
            ],
        ], 200);
    }

    public function changePassword(Request $request)
    {
        $validated = $request->validate([
            'worker_id' => 'required|string',
            'current_password' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $worker = Worker::where(
            'worker_id',
            $validated['worker_id']
        )->first();

        if (!$worker) {
            return response()->json([
                'message' => 'Worker not found.',
            ], 404);
        }

        if (
            !Hash::check(
                $validated['current_password'],
                $worker->password
            )
        ) {
            return response()->json([
                'message' => 'The current password is incorrect.',
            ], 401);
        }

        if (
            Hash::check(
                $validated['password'],
                $worker->password
            )
        ) {
            return response()->json([
                'message' =>
                    'Your new password must be different from the current password.',
            ], 400);
        }

        $worker->update([
            'password' => Hash::make(
                $validated['password']
            ),
            'must_change_password' => false,
        ]);

        return response()->json([
            'message' =>
                'Password changed successfully.',
            'worker' => [
                'id' => $worker->id,
                'first_name' => $worker->first_name,
                'last_name' => $worker->last_name,
                'worker_id' => $worker->worker_id,
                'mobile' => $worker->mobile,
                'must_change_password' =>
                    $worker->must_change_password,
            ],
        ], 200);
    }
}