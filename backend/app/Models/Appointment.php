<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Appointment extends Model
{
    use HasFactory;

    protected $fillable = [
        'driver_id',
        'truck_plate',
        'coming_from',
        'livestock_load',
        'preferred_datetime',
        'gcash_account',
        'status',
        'arrived_at',
    ];

    protected $casts = [
        'preferred_datetime' => 'datetime',
        'arrived_at' => 'datetime',
    ];

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }

    public function assignments()
{
    return $this->hasMany(WorkerAssignment::class);
}
}