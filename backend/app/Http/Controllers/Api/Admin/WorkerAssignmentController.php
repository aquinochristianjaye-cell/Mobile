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
        \Log::info('DEPLOY START');

        $validated = $request->validate([
            'appointment_id' => 'required|exists:appointments,id',
            'worker_id' => 'required|exists:workers,id',
            'wash_bay_id' => 'required|integer|in:1,2',
        ]);

        \Log::info('DEPLOY VALIDATION DONE');

        $appointment = Appointment::find(
            $validated['appointment_id']
        );

        if (!$appointment) {
            return response()->json([
                'message' => 'Appointment not found.',
            ], 404);
        }

        if ($appointment->status === 'cancelled') {
            return response()->json([
                'message' =>
                    'This appointment has been cancelled and cannot be deployed.',
            ], 400);
        }

        $existingAssignment = WorkerAssignment::where(
            'appointment_id',
            $validated['appointment_id']
        )
        ->whereIn('status', ['assigned', 'washing'])
        ->whereHas('appointment', function ($query) {
            $query->whereIn('status', [
                'assigned',
                'arrived',
                'washing',
            ]);
        })
        ->first();

        \Log::info('DEPLOY APPOINTMENT CHECK DONE');

        if ($existingAssignment) {
            return response()->json([
                'message' => 'This truck is already assigned.',
            ], 400);
        }

        $workerBusy = WorkerAssignment::where(
            'worker_id',
            $validated['worker_id']
        )
        ->whereIn('status', ['assigned', 'washing'])
        ->whereHas('appointment', function ($query) {
            $query->whereIn('status', [
                'assigned',
                'arrived',
                'washing',
            ]);
        })
        ->first();

        \Log::info('DEPLOY WORKER CHECK DONE');

        if ($workerBusy) {
            return response()->json([
                'message' =>
                    'This worker is already assigned to another truck.',
            ], 400);
        }

        $worker = Worker::find(
            $validated['worker_id']
        );

        if (!$worker) {
            return response()->json([
                'message' => 'Worker not found.',
            ], 404);
        }

        if (!$worker->is_available) {
            return response()->json([
                'message' =>
                    'Cannot deploy. Worker is unavailable.',
            ], 400);
        }

        if ($worker->is_on_break) {
            return response()->json([
                'message' =>
                    'Cannot deploy. Worker is currently on break.',
            ], 400);
        }

        \Log::info(
            'DEPLOY WORKER AVAILABILITY CHECK DONE'
        );

        $bayBusy = WorkerAssignment::where(
            'wash_bay_id',
            $validated['wash_bay_id']
        )
        ->whereIn('status', ['assigned', 'washing'])
        ->whereHas('appointment', function ($query) {
            $query->whereIn('status', [
                'assigned',
                'arrived',
                'washing',
            ]);
        })
        ->first();

        \Log::info('DEPLOY BAY CHECK DONE');

        if ($bayBusy) {
            return response()->json([
                'message' =>
                    'This wash bay is currently in use.',
            ], 400);
        }

        $assignment = WorkerAssignment::create([
            'appointment_id' =>
                $validated['appointment_id'],
            'worker_id' =>
                $validated['worker_id'],
            'wash_bay_id' =>
                $validated['wash_bay_id'],
            'status' => 'assigned',
        ]);

        \Log::info('DEPLOY CREATE DONE');

        $appointment->update([
            'status' => 'assigned',
        ]);

        \Log::info(
            'DEPLOY APPOINTMENT STATUS UPDATED'
        );

        $assignment->load([
            'worker',
            'appointment.driver',
        ]);

        \Log::info('DEPLOY RELATION LOAD DONE');

        return response()->json([
            'message' =>
                'Truck deployed successfully.',
            'assignment' => $assignment,
        ], 201);
    }

    public function active()
    {
        $assignments = WorkerAssignment::with([
            'worker',
            'appointment.driver',
        ])
        ->whereIn('status', ['assigned', 'washing'])
        ->whereHas('appointment', function ($query) {
            $query->whereIn('status', [
                'assigned',
                'arrived',
                'washing',
            ]);
        })
        ->orderBy('created_at', 'asc')
        ->get();

        return response()->json([
            'assignments' => $assignments,
        ], 200);
    }

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