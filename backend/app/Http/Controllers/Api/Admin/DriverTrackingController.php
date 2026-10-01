<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Driver;

class DriverTrackingController extends Controller
{
    public function index()
    {
        $drivers = Driver::query()
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->select([
                'id',
                'name',
                'mobile',
                'latitude',
                'longitude',
                'location_updated_at',
            ])
            ->orderByDesc('location_updated_at')
            ->get();

        return response()->json([
            'drivers' => $drivers,
        ]);
    }
}