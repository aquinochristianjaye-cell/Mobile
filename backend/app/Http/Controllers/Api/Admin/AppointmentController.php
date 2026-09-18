<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Appointment;

class AppointmentController extends Controller
{
    public function index()
    {
        $appointments = Appointment::with('driver')
            ->where('status', 'scheduled')
            ->orderBy('preferred_datetime', 'asc')
            ->get();

        return response()->json([
            'appointments' => $appointments,
        ], 200);
    }
}