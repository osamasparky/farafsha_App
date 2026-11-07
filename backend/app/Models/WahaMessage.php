<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WahaMessage extends Model
{
    protected $fillable = ['waha_session_id', 'direction', 'chat_id', 'body', 'status', 'waha_message_id', 'idempotency_key', 'metadata', 'last_error', 'sent_at'];
    protected $casts = ['metadata' => 'array', 'sent_at' => 'datetime'];

    public function session(): BelongsTo { return $this->belongsTo(WahaSession::class, 'waha_session_id'); }
}
