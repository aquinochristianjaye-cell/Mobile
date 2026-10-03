<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdminEmailVerification extends Model
{
    protected $table = 'admin_email_verifications';

    protected $fillable = [
        'first_name',
        'last_name',
        'email',
        'password',
        'verification_code',
        'expires_at',
    ];

    protected $hidden = [
        'password',
        'verification_code',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];
}