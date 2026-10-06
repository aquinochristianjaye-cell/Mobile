<?php

namespace App\Http\Controllers\Api\Worker;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\Worker;
use Illuminate\Http\Request;

class WorkerController extends Controller
{
    public function test()
    {
        return response()->json([
            'message' => 'Worker Controller is working'
        ]);
    }

    public function driverLocation($driverId)
    {
        $driver = Driver::find($driverId);

        if (!$driver) {
            return response()->json([
                'message' => 'Driver not found'
            ], 404);
        }

        return response()->json([
            'driver_id' => $driver->id,
            'driver_name' => $driver->name,
            'latitude' => $driver->latitude,
            'longitude' => $driver->longitude,
            'location_updated_at' => $driver->location_updated_at,
        ]);
    }

    // ----------------------------------------------------------
    // GET WORKER AVAILABILITY
    // ----------------------------------------------------------

    public function getAvailability($workerId)
    {
        $worker = Worker::find($workerId);

        if (!$worker) {
            return response()->json([
                'message' => 'Worker not found.',
            ], 404);
        }

        return response()->json([
            'worker_id' => $worker->id,
            'is_available' => (bool) $worker->is_available,
        ], 200);
    }

    // ----------------------------------------------------------
    // UPDATE WORKER AVAILABILITY
    // ----------------------------------------------------------

    public function updateAvailability($workerId, Request $request)
    {
        $worker = Worker::find($workerId);

        if (!$worker) {
            return response()->json([
                'message' => 'Worker not found.',
            ], 404);
        }

        $validated = $request->validate([
            'is_available' => ['required', 'boolean'],
        ]);

        // If the worker is trying to become unavailable,
        // make sure at least 2 workers remain available.
        if (!$validated['is_available'] && $worker->is_available) {
            $availableWorkers = Worker::where('is_available', true)
                ->count();

            if ($availableWorkers <= 2) {
                return response()->json([
                    'message' =>
                        'Cannot set unavailable. At least 2 workers must remain available.',
                ], 400);
            }
        }

        $worker->is_available = $validated['is_available'];
        $worker->save();

        return response()->json([
            'message' => $worker->is_available
                ? 'Worker is now available.'
                : 'Worker is now unavailable.',
            'worker_id' => $worker->id,
            'is_available' => (bool) $worker->is_available,
        ], 200);
    }

    // ----------------------------------------------------------
    // GET WORKER BREAK
    // ----------------------------------------------------------

    public function getBreak($workerId)
    {
        $worker = Worker::find($workerId);

        if (!$worker) {
            return response()->json([
                'message' => 'Worker not found.',
            ], 404);
        }

        return response()->json([
            'worker_id' => $worker->id,
            'is_on_break' => (bool) $worker->is_on_break,
        ], 200);
    }

    // ----------------------------------------------------------
    // UPDATE WORKER BREAK
    // ----------------------------------------------------------

    public function updateBreak($workerId, Request $request)
    {
        $worker = Worker::find($workerId);

        if (!$worker) {
            return response()->json([
                'message' => 'Worker not found.',
            ], 404);
        }

        $validated = $request->validate([
            'is_on_break' => ['required', 'boolean'],
        ]);

        $worker->is_on_break = $validated['is_on_break'];
        $worker->save();

        return response()->json([
            'message' => $worker->is_on_break
                ? 'Worker is now on break.'
                : 'Worker is no longer on break.',
            'worker_id' => $worker->id,
            'is_on_break' => (bool) $worker->is_on_break,
        ], 200);
    }
}
