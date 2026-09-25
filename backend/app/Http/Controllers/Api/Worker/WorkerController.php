<?php

namespace App\Http\Controllers\Api\Worker;

use App\Http\Controllers\Controller;
use App\Models\Driver;

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
}