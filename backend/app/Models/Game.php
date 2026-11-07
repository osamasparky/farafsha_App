<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Game extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'subtitle',
        'description',
        'instructions',
        'icon',
        'cover_image',
        'badge_text',
        'category',
        'template_type',
        'game_mode',
        'min_players',
        'max_players',
        'default_rounds',
        'default_duration_seconds',
        'difficulty_levels',
        'rules_config',
        'is_active',
        'is_featured',
        'sort_order',
    ];

    protected $casts = [
        'difficulty_levels' => 'array',
        'rules_config' => 'array',
        'is_active' => 'boolean',
        'is_featured' => 'boolean',
        'min_players' => 'integer',
        'max_players' => 'integer',
        'default_rounds' => 'integer',
        'default_duration_seconds' => 'integer',
        'sort_order' => 'integer',
    ];

    protected $appends = [
        'cover_image_url',
    ];

    public function getCoverImageUrlAttribute(): ?string
    {
        if (!$this->cover_image) {
            return null;
        }

        if (str_starts_with($this->cover_image, 'http://') || str_starts_with($this->cover_image, 'https://')) {
            return $this->cover_image;
        }

        return url('storage/' . ltrim($this->cover_image, '/'));
    }

    public function contentItems(): HasMany
    {
        return $this->hasMany(ContentItem::class);
    }

    public function packs(): HasMany
    {
        return $this->hasMany(Pack::class);
    }

    public function sessions(): HasMany
    {
        return $this->hasMany(GameSession::class);
    }
}
