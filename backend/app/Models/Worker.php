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
    ];

    protected $hidden = [
        'password',
    ];

    public function assignments()
    {
        return $this->hasMany(WorkerAssignment::class);
    }
}