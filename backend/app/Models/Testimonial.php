<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Spatie\Translatable\HasTranslations;

class Testimonial extends Model
{
    use HasFactory, HasTranslations;

    protected $fillable = [
        'author_name',
        'avatar',
        'source',
        'rating',
        'content',
        'country_code',
        'is_approved',
        'sort_order',
    ];

    public array $translatable = [
        'content',
    ];

    protected $casts = [
        'rating' => 'integer',
        'is_approved' => 'boolean',
        'sort_order' => 'integer',
    ];

    public function scopeApproved($query)
    {
        return $query->where('is_approved', true)->orderBy('sort_order')->orderByDesc('created_at');
    }
}

