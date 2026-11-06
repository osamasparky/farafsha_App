<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WahaWebhookEvent extends Model
{
    protected $fillable = ['event_id', 'event_name', 'session', 'payload', 'received_at', 'processed_at', 'processing_error'];
    protected $casts = ['payload' => 'array', 'received_at' => 'datetime', 'processed_at' => 'datetime'];
}
