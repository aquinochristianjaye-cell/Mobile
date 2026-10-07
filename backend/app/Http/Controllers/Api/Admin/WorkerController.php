<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Worker;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

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
        )
        ->orderBy('first_name')
        ->get();

        return response()->json([
            'workers' => $workers,
        ], 200);
    }

    public function resetPassword(
        Request $request,
        $workerId
    ) {
        $validated = $request->validate([
            'password' => 'required|string|min:6|confirmed',
        ]);

        $worker = Worker::find($workerId);

        if (!$worker) {
            return response()->json([
                'message' => 'Worker not found.',
            ], 404);
        }

        $worker->update([
            'password' => Hash::make(
                $validated['password']
            ),
            'must_change_password' => true,
        ]);

        return response()->json([
            'message' =>
                'Worker password has been reset successfully.',
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