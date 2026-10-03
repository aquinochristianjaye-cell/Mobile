<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdminPasswordReset extends Model
{
    protected $table = 'admin_password_resets';

    protected $fillable = [
        'email',
        'code',
        'attempts',
        'expires_at',
    ];

    protected $hidden = [
        'code',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];
}