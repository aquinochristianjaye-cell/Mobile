<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAccount;
use App\Models\AdminEmailVerification;
use App\Models\AdminPasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class AdminAuthController extends Controller
{
    private const MAX_RESET_ATTEMPTS = 5;

    /**
     * Send email verification code for Admin registration.
     */
    public function register(Request $request)
    {
        $validated = $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // Check if the email is already registered as an Admin.
        if (AdminAccount::where('email', $validated['email'])->exists()) {
            return response()->json([
                'message' => 'This email is already registered.',
            ], 422);
        }

        // Generate a random 6-digit verification code.
        $verificationCode = (string) random_int(100000, 999999);

        // Remove any previous pending verification for this email.
        AdminEmailVerification::where(
            'email',
            $validated['email']
        )->delete();

        // Store the pending registration.
        AdminEmailVerification::create([
            'first_name' => $validated['first_name'],
            'last_name' => $validated['last_name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'verification_code' => Hash::make($verificationCode),
            'expires_at' => now()->addMinutes(5),
        ]);

        // Send the verification code to the entered email.
        Mail::raw(
            "Hello {$validated['first_name']},\n\n"
            . "Your Aquino Wash Station Admin verification code is:\n\n"
            . "{$verificationCode}\n\n"
            . "This code will expire in 5 minutes.\n\n"
            . "If you did not request this account, you can safely ignore this email.\n\n"
            . "Aquino Wash Station",
            function ($message) use ($validated) {
                $message->to($validated['email'])
                    ->subject('Aquino Wash Station - Email Verification Code');
            }
        );

        return response()->json([
            'message' => 'Verification code sent successfully.',
            'email' => $validated['email'],
        ], 200);
    }

    /**
     * Verify the email verification code and create the Admin account.
     */
    public function verifyCode(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'code' => 'required|digits:6',
        ]);

        $verification = AdminEmailVerification::where(
            'email',
            $validated['email']
        )->first();

        if (!$verification) {
            return response()->json([
                'message' => 'No pending verification was found for this email.',
            ], 404);
        }

        // Check if the code has expired.
        if ($verification->expires_at->isPast()) {
            $verification->delete();

            return response()->json([
                'message' => 'The verification code has expired. Please request a new code.',
            ], 422);
        }

        // Check the submitted code against the hashed code.
        if (!Hash::check(
            $validated['code'],
            $verification->verification_code
        )) {
            return response()->json([
                'message' => 'Invalid verification code.',
            ], 422);
        }

        // Make sure another account wasn't created with this email.
        if (AdminAccount::where('email', $verification->email)->exists()) {
            $verification->delete();

            return response()->json([
                'message' => 'This email is already registered.',
            ], 422);
        }

        // Create the actual Admin account only after successful verification.
        $admin = AdminAccount::create([
            'first_name' => $verification->first_name,
            'last_name' => $verification->last_name,
            'email' => $verification->email,
            'password' => $verification->password,
        ]);

        // Remove the temporary verification record.
        $verification->delete();

        return response()->json([
            'message' => 'Admin account registered successfully.',
            'admin' => [
                'id' => $admin->id,
                'first_name' => $admin->first_name,
                'last_name' => $admin->last_name,
                'email' => $admin->email,
            ],
        ], 201);
    }

    /**
     * Send a password reset code.
     * Always returns the same response so attackers can't
     * discover which emails are registered.
     */
    public function forgotPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
        ]);

        $admin = AdminAccount::where(
            'email',
            $validated['email']
        )->first();

        if ($admin) {
            $code = (string) random_int(100000, 999999);

            AdminPasswordReset::where('email', $admin->email)->delete();

            AdminPasswordReset::create([
                'email' => $admin->email,
                'code' => Hash::make($code),
                'attempts' => 0,
                'expires_at' => now()->addMinutes(5),
            ]);

            Mail::raw(
                "Hello {$admin->first_name},\n\n"
                . "Your Aquino Wash Station password reset code is:\n\n"
                . "{$code}\n\n"
                . "This code will expire in 5 minutes.\n\n"
                . "If you did not request a password reset, you can safely ignore this email. Your password will not change.\n\n"
                . "Aquino Wash Station",
                function ($message) use ($admin) {
                    $message->to($admin->email)
                        ->subject('Aquino Wash Station - Password Reset Code');
                }
            );
        }

        return response()->json([
            'message' => 'If that email is registered, a reset code has been sent.',
        ], 200);
    }

    /**
     * Verify the reset code and set the new password.
     */
    public function resetPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'code' => 'required|digits:6',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $invalid = response()->json([
            'message' => 'Invalid or expired code.',
        ], 422);

        $reset = AdminPasswordReset::where(
            'email',
            $validated['email']
        )->first();

        if (!$reset) {
            return $invalid;
        }

        if ($reset->expires_at->isPast()) {
            $reset->delete();

            return response()->json([
                'message' => 'The code has expired. Please request a new one.',
            ], 422);
        }

        if (!Hash::check($validated['code'], $reset->code)) {
            $reset->attempts++;

            if ($reset->attempts >= self::MAX_RESET_ATTEMPTS) {
                $reset->delete();

                return response()->json([
                    'message' => 'Too many wrong attempts. Please request a new code.',
                ], 422);
            }

            $reset->save();

            return response()->json([
                'message' => 'Invalid or expired code.',
            ], 422);
        }

        $admin = AdminAccount::where(
            'email',
            $validated['email']
        )->first();

        if (!$admin) {
            $reset->delete();

            return $invalid;
        }

        $admin->forceFill([
            'password' => Hash::make($validated['password']),
        ])->save();

        // Single use: the code can never be reused.
        $reset->delete();

        return response()->json([
            'message' => 'Password reset successfully. You can now sign in.',
        ], 200);
    }

    /**
     * Admin login.
     */
    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $admin = AdminAccount::where(
            'email',
            $validated['email']
        )->first();

        if (!$admin || !Hash::check(
            $validated['password'],
            $admin->password
        )) {
            return response()->json([
                'message' => 'Invalid email or password'
            ], 401);
        }

        return response()->json([
            'message' => 'Login successful',
            'admin' => [
                'id' => $admin->id,
                'first_name' => $admin->first_name,
                'last_name' => $admin->last_name,
                'email' => $admin->email,
            ],
        ], 200);
    }
}