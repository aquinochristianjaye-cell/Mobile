<?php

namespace App\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use Illuminate\Http\Request;

class DriverController extends Controller
{
    public function test()
    {
        return response()->json([
            'message' => 'Driver Controller is working'
        ]);
    }

    public function updateLocation(Request $request)
    {
        $validated = $request->validate([
            'driver_id' => ['required', 'integer'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ]);

        $driver = Driver::find($validated['driver_id']);

        if (!$driver) {
            return response()->json([
                'message' => 'Driver not found'
            ], 404);
        }

        $driver->update([
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'location_updated_at' => now(),
        ]);

        return response()->json([
            'message' => 'Driver location saved',
            'location' => [
                'driver_id' => $driver->id,
                'latitude' => $driver->latitude,
                'longitude' => $driver->longitude,
                'location_updated_at' => $driver->location_updated_at,
            ],
        ]);
    }
}