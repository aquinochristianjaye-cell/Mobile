<?php

namespace App\Http\Controllers\Api\Worker;

use App\Http\Controllers\Controller;
use App\Models\WorkerAssignment;

class WorkerAssignmentController extends Controller
{
    public function index($workerId)
    {
        $assignments = WorkerAssignment::with([
            'appointment.driver',
        ])
        ->where('worker_id', $workerId)
        ->whereIn('status', ['assigned', 'washing'])
        ->orderBy('created_at', 'desc')
        ->get();

        return response()->json([
            'assignments' => $assignments,
        ], 200);
    }

    public function completed($workerId)
    {
        $assignments = WorkerAssignment::with([
            'appointment.driver',
        ])
        ->where('worker_id', $workerId)
        ->where('status', 'completed')
        ->orderBy('finished_at', 'desc')
        ->get();

        return response()->json([
            'assignments' => $assignments,
        ], 200);
    }

    public function start($assignmentId)
    {
        $assignment = WorkerAssignment::with([
            'appointment.driver',
        ])->find($assignmentId);

        if (!$assignment) {
            return response()->json([
                'message' => 'Assignment not found.',
            ], 404);
        }

        if ($assignment->status !== 'assigned') {
            return response()->json([
                'message' => 'This assignment cannot be started.',
            ], 400);
        }

        // Truck must have arrived before washing can start.
        if (
            !$assignment->appointment ||
            $assignment->appointment->status !== 'arrived'
        ) {
            return response()->json([
                'message' =>
                    'The truck has not arrived yet. Please wait for the driver to scan the QR code.',
            ], 400);
        }

        // Record exact washing start time.
        $assignment->started_at = now();
        $assignment->status = 'washing';
        $assignment->save();

        // Update the appointment status so the Driver UI
        // knows that washing has started.
        $assignment->appointment->update([
            'status' => 'washing',
        ]);

        return response()->json([
            'message' => 'Washing started.',
            'assignment' => $assignment->load([
                'appointment.driver',
            ]),
        ], 200);
    }

    public function finish($assignmentId)
    {
        $assignment = WorkerAssignment::with([
            'appointment.driver',
        ])->find($assignmentId);

        if (!$assignment) {
            return response()->json([
                'message' => 'Assignment not found.',
            ], 404);
        }

        if ($assignment->status !== 'washing') {
            return response()->json([
                'message' =>
                    'This assignment cannot be finished.',
            ], 400);
        }

        // Record exact washing finish time.
        $assignment->finished_at = now();
        $assignment->status = 'completed';
        $assignment->save();

        // Update the appointment status so the Driver UI
        // knows that washing has been completed.
        $assignment->appointment->update([
            'status' => 'completed',
        ]);

        return response()->json([
            'message' => 'Washing completed.',
            'assignment' => $assignment,
        ], 200);
    }
}

