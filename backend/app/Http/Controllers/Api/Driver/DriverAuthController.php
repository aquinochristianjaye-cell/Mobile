<?php

namespace App\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\DriverPasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class DriverAuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:drivers,email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $driver = Driver::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        return response()->json([
            'message' => 'Driver registered successfully',
            'driver' => $driver,
        ], 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $driver = Driver::where(
            'email',
            $validated['email']
        )->first();

        if (
            !$driver ||
            !Hash::check(
                $validated['password'],
                $driver->password
            )
        ) {
            return response()->json([
                'message' => 'Invalid email or password',
            ], 401);
        }

        return response()->json([
            'message' => 'Login successful',
            'driver' => [
                'id' => $driver->id,
                'name' => $driver->name,
                'email' => $driver->email,
            ],
        ], 200);
    }

    // ----------------------------------------------------------
    // FORGOT PASSWORD
    // ----------------------------------------------------------

    public function forgotPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
        ]);

        $driver = Driver::where(
            'email',
            $validated['email']
        )->first();

        // Use a generic response so the API does not reveal
        // whether an email belongs to a Driver account.
        if (!$driver) {
            return response()->json([
                'message' =>
                    'If the email is registered, a verification code has been sent.',
            ], 200);
        }

        // Remove any previous reset codes for this Driver.
        DriverPasswordReset::where(
            'driver_id',
            $driver->id
        )->delete();

        // Generate a 6-digit verification code.
        $code = str_pad(
            (string) random_int(0, 999999),
            6,
            '0',
            STR_PAD_LEFT
        );

        DriverPasswordReset::create([
            'driver_id' => $driver->id,
            'code' => Hash::make($code),
            'attempts' => 0,
            'expires_at' => now()->addMinutes(5),
        ]);

        Mail::raw(
            "Your Aquino Wash Station password reset code is: {$code}\n\n"
            . "This code will expire in 5 minutes.\n\n"
            . "If you did not request a password reset, "
            . "please ignore this email.",
            function ($message) use ($driver) {
                $message
                    ->to($driver->email)
                    ->subject(
                        'Aquino Wash Station - Password Reset Code'
                    );
            }
        );

        return response()->json([
            'message' =>
                'If the email is registered, a verification code has been sent.',
        ], 200);
    }

    // ----------------------------------------------------------
    // RESET PASSWORD
    // ----------------------------------------------------------

    public function resetPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'code' => 'required|string|size:6',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $driver = Driver::where(
            'email',
            $validated['email']
        )->first();

        if (!$driver) {
            return response()->json([
                'message' => 'Invalid verification request.',
            ], 400);
        }

        $reset = DriverPasswordReset::where(
            'driver_id',
            $driver->id
        )->first();

        if (!$reset) {
            return response()->json([
                'message' =>
                    'No password reset request was found. Please request a new code.',
            ], 400);
        }

        // Check expiration.
        if ($reset->expires_at->isPast()) {
            $reset->delete();

            return response()->json([
                'message' =>
                    'The verification code has expired. Please request a new code.',
            ], 400);
        }

        // Maximum of 5 incorrect attempts.
        if ($reset->attempts >= 5) {
            $reset->delete();

            return response()->json([
                'message' =>
                    'Too many incorrect attempts. Please request a new code.',
            ], 429);
        }

        // Check the verification code.
        if (!Hash::check(
            $validated['code'],
            $reset->code
        )) {
            $reset->increment('attempts');

            return response()->json([
                'message' =>
                    'Invalid verification code.',
                'attempts_remaining' =>
                    max(0, 5 - $reset->attempts),
            ], 400);
        }

        // Update the Driver password.
        $driver->update([
            'password' => Hash::make(
                $validated['password']
            ),
        ]);

        // Delete the code so it cannot be reused.
        $reset->delete();

        return response()->json([
            'message' =>
                'Password reset successfully. You can now log in with your new password.',
        ], 200);
    }
}