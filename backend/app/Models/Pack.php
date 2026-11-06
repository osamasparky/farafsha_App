<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pack extends Model
{
    use HasFactory;

    protected $fillable = [
        'game_id',
        'name',
        'slug',
        'description',
        'cover_image',
        'dialect',
        'age_rating',
        'is_free',
        'price',
        'currency',
        'cards_count',
        'is_active',
        'version',
    ];

    protected $casts = [
        'is_free' => 'boolean',
        'is_active' => 'boolean',
        'price' => 'decimal:2',
        'cards_count' => 'integer',
    ];

    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class);
    }

    public function contentItems(): HasMany
    {
        return $this->hasMany(ContentItem::class);
    }
}
