<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WahaSession extends Model
{
    protected $fillable = ['name', 'status', 'phone', 'metadata', 'last_seen_at'];
    protected $casts = ['metadata' => 'array', 'last_seen_at' => 'datetime'];

    public function messages(): HasMany { return $this->hasMany(WahaMessage::class); }
}
