<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;
use Spatie\Translatable\HasTranslations;

class SitePage extends Model
{
    use HasFactory, HasTranslations, LogsActivity;

    protected $fillable = [
        'slug',
        'title',
        'subtitle',
        'seo_title',
        'seo_description',
        'og_image',
        'status',
        'published_at',
        'blocks',
    ];

    public array $translatable = [
        'title',
        'subtitle',
    ];

    protected $casts = [
        'blocks' => 'array',
        'published_at' => 'datetime',
    ];

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['slug', 'status', 'published_at'])
            ->logOnlyDirty();
    }

    public function isPublished(): bool
    {
        return $this->status === 'published' && ($this->published_at === null || $this->published_at->isPast());
    }

    public function scopePublished($query)
    {
        return $query->where('status', 'published')
            ->where(function ($q) {
                $q->whereNull('published_at')
                    ->orWhere('published_at', '<=', now());
            });
    }
}

