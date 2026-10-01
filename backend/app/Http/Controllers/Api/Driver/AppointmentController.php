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

        $appointment = Appointment::create([
            'driver_id' => $validated['driver_id'],
            'truck_plate' => $validated['truck_plate'],
            'coming_from' => $validated['coming_from'],
            'livestock_load' => $validated['livestock_load'],
            'preferred_datetime' => $validated['preferred_datetime'],
            'gcash_account' => $validated['gcash_account'] ?? null,
            'status' => 'pending',
        ]);

        // Create notification for Admin
        Notification::create([
            'recipient' => 'admin',
            'title' => 'New Appointment',
            'message' => 'Truck ' . $appointment->truck_plate .
                ' has submitted a new wash appointment.',
            'appointment_id' => $appointment->id,
        ]);

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

        // Notify Admin
        Notification::create([
            'recipient' => 'admin',
            'title' => 'Truck Arrived',
            'message' => 'Truck ' . $appointment->truck_plate .
                ' driven by ' . $appointment->driver->name .
                ' has arrived.',
            'appointment_id' => $appointment->id,
        ]);

        // Notify Worker
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

    public function status($driverId, $appointmentId)
    {
        $appointment = Appointment::where('id', $appointmentId)
            ->where('driver_id', $driverId)
            ->first();

        if (!$appointment) {
            return response()->json([
                'message' => 'Appointment not found',
            ], 404);
        }

        return response()->json([
            'appointment' => [
                'id' => $appointment->id,
                'driver_id' => $appointment->driver_id,
                'truck_plate' => $appointment->truck_plate,
                'coming_from' => $appointment->coming_from,
                'livestock_load' => $appointment->livestock_load,
                'preferred_datetime' => $appointment->preferred_datetime,
                'status' => $appointment->status,
                'arrived_at' => $appointment->arrived_at,
            ],
        ], 200);
    }

    public function updateLocation(Request $request)
    {
        $validated = $request->validate([
            'driver_id' => 'required|exists:drivers,id',
            'appointment_id' => 'required|exists:appointments,id',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $appointment = Appointment::where(
            'id',
            $validated['appointment_id']
        )
            ->where(
                'driver_id',
                $validated['driver_id']
            )
            ->first();

        if (!$appointment) {
            return response()->json([
                'message' => 'Appointment does not belong to this driver.',
            ], 403);
        }

        // Track the driver while the appointment is still active.
        if (!in_array($appointment->status, [
            'pending',
            'assigned',
            'arrived',
        ])) {
            return response()->json([
                'message' => 'Location tracking is not active for this appointment.',
            ], 400);
        }

        $appointment->update([
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
        ]);

        return response()->json([
            'message' => 'Location updated successfully.',
        ], 200);
    }
}