<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WorkerAssignment extends Model
{
    use HasFactory;

   protected $fillable = [
    'worker_id',
    'appointment_id',
    'wash_bay_id',
    'status',
];

    public function worker()
    {
        return $this->belongsTo(Worker::class);
    }

    public function appointment()
    {
        return $this->belongsTo(Appointment::class);
    }
}