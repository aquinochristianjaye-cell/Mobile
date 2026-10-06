<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class Worker extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'first_name',
        'last_name',
        'worker_id',
        'mobile',
        'password',
        'is_available',
        'is_on_break',
    ];

    protected $hidden = [
        'password',
    ];

    protected $casts = [
        'is_available' => 'boolean',
        'is_on_break' => 'boolean',
    ];

    public function assignments()
    {
        return $this->hasMany(WorkerAssignment::class);
    }
}