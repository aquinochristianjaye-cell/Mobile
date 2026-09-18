<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Worker;
use App\Models\WorkerAssignment;
use Illuminate\Http\Request;

class WorkerAssignmentController extends Controller
{
    public function deploy(Request $request)
    {
        $validated = $request->validate([
            'appointment_id' => 'required|exists:appointments,id',
            'worker_id' => 'required|exists:workers,id',
            'wash_bay_id' => 'required|integer|in:1,2',
        ]);

        // Check if this truck is already assigned
        $existingAssignment = WorkerAssignment::where(
            'appointment_id',
            $validated['appointment_id']
        )
        ->whereIn('status', ['assigned', 'washing'])
        ->first();

        if ($existingAssignment) {
            return response()->json([
                'message' => 'This truck is already assigned.',
            ], 400);
        }

        // Check if the selected worker is already working
        $workerBusy = WorkerAssignment::where(
            'worker_id',
            $validated['worker_id']
        )
        ->whereIn('status', ['assigned', 'washing'])
        ->first();

        if ($workerBusy) {
            return response()->json([
                'message' => 'This worker is already assigned to another truck.',
            ], 400);
        }

        // Check if the selected wash bay is already in use
        $bayBusy = WorkerAssignment::where(
            'wash_bay_id',
            $validated['wash_bay_id']
        )
        ->whereIn('status', ['assigned', 'washing'])
        ->first();

        if ($bayBusy) {
            return response()->json([
                'message' => 'This wash bay is currently in use.',
            ], 400);
        }

        $assignment = WorkerAssignment::create([
            'appointment_id' => $validated['appointment_id'],
            'worker_id' => $validated['worker_id'],
            'wash_bay_id' => $validated['wash_bay_id'],
            'status' => 'assigned',
        ]);

        return response()->json([
            'message' => 'Truck deployed successfully.',
            'assignment' => $assignment->load([
                'worker',
                'appointment.driver',
            ]),
        ], 201);
    }

    public function active()
    {
        $assignments = WorkerAssignment::with([
            'worker',
            'appointment.driver',
        ])
        ->whereIn('status', ['assigned', 'washing'])
        ->orderBy('created_at', 'asc')
        ->get();

        return response()->json([
            'assignments' => $assignments,
        ], 200);
    }

    // ==========================================================
    // COMPLETED TRUCKS
    // ==========================================================

    public function completed()
    {
        $assignments = WorkerAssignment::with([
            'worker',
            'appointment.driver',
        ])
        ->where('status', 'completed')
        ->orderBy('updated_at', 'desc')
        ->get();

        return response()->json([
            'assignments' => $assignments,
        ], 200);
    }
}

