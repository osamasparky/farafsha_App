<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ContentItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'game_id',
        'pack_id',
        'type',
        'prompt',
        'answer',
        'distractors',
        'forbidden_words',
        'hints',
        'acceptable_alternatives',
        'explanation',
        'media_type',
        'media_url',
        'source_reference',
        'dialect',
        'difficulty',
        'age_rating',
        'is_sensitive',
        'status',
        'report_count',
        'is_active',
    ];

    protected $casts = [
        'distractors' => 'array',
        'forbidden_words' => 'array',
        'hints' => 'array',
        'acceptable_alternatives' => 'array',
        'is_sensitive' => 'boolean',
        'is_active' => 'boolean',
        'report_count' => 'integer',
    ];

    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class);
    }

    public function pack(): BelongsTo
    {
        return $this->belongsTo(Pack::class);
    }
}
