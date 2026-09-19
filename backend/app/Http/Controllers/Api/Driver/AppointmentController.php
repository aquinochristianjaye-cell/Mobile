<?php

namespace App\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use Illuminate\Http\Request;
use App\Models\Notification;

class AppointmentController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'driver_id' => 'required|exists:drivers,id',
            'truck_plate' => 'required|string|max:255',
            'coming_from' => 'required|string|max:255',
            'livestock_load' => 'required|string|max:255',
            'preferred_datetime' => 'required|date',
            'gcash_account' => 'nullable|string|max:255',
        ]);

        $appointment = Appointment::create($validated);

        return response()->json([
            'message' => 'Appointment created successfully',
            'appointment' => $appointment,
        ], 201);
    }

    public function checkIn(Request $request)
{
    $validated = $request->validate([
        'qr_code' => 'required|string',
    ]);

    $qrCode = $validated['qr_code'];

    if (!str_starts_with($qrCode, 'WASH-APPOINTMENT-')) {
        return response()->json([
            'message' => 'Invalid QR code',
        ], 400);
    }

    $appointmentId = str_replace(
        'WASH-APPOINTMENT-',
        '',
        $qrCode
    );

    if (!is_numeric($appointmentId)) {
        return response()->json([
            'message' => 'Invalid appointment ID',
        ], 400);
    }

    $appointment = Appointment::with('driver')
        ->find($appointmentId);

    if (!$appointment) {
        return response()->json([
            'message' => 'Appointment not found',
        ], 404);
    }

    if ($appointment->status === 'arrived') {
        return response()->json([
            'message' => 'Truck has already arrived',
            'appointment' => $appointment,
        ], 409);
    }

    $appointment->update([
        'status' => 'arrived',
        'arrived_at' => now(),
    ]);

    Notification::create([
    'recipient' => 'admin',
    'title' => 'Truck Arrived',
    'message' => 'Truck ' . $appointment->truck_plate .
        ' driven by ' . $appointment->driver->name .
        ' has arrived.',
    'appointment_id' => $appointment->id,
]);

Notification::create([
    'recipient' => 'worker',
    'title' => 'Truck Arrived',
    'message' => 'Truck ' . $appointment->truck_plate .
        ' driven by ' . $appointment->driver->name .
        ' has arrived.',
    'appointment_id' => $appointment->id,
]);

    return response()->json([
        'message' => 'Truck arrival recorded successfully',
        'appointment' => $appointment->load('driver'),
    ], 200);
}

    public function completed($driverId)
    {
        $appointments = Appointment::where('driver_id', $driverId)
            ->where('status', 'completed')
            ->orderByDesc('preferred_datetime')
            ->get();

        return response()->json([
            'appointments' => $appointments,
        ], 200);
    }
}