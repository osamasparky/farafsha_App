<?php

namespace App\Models;

use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable implements FilamentUser
{
    use HasApiTokens, HasFactory, Notifiable, HasRoles;

    protected $fillable = [
        'name',
        'username',
        'email',
        'phone',
        'phone_verified_at',
        'status',
        'deletion_requested_at',
        'password',
        'avatar',
        'last_seen_at',
        'current_room_code',
        'is_admin',
        'level',
        'total_score',
        'weekly_score',
        'wins_count',
        'games_played',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone_verified_at' => 'datetime',
            'deletion_requested_at' => 'datetime',
            'last_seen_at' => 'datetime',
            'password' => 'hashed',
            'is_admin' => 'boolean',
            'level' => 'integer',
            'total_score' => 'integer',
            'weekly_score' => 'integer',
            'wins_count' => 'integer',
            'games_played' => 'integer',
        ];
    }

    public function canAccessPanel(Panel $panel): bool
    {
        return (bool) $this->is_admin && ($this->status === null || $this->status === 'active');
    }

    public function socialAccounts()
    {
        return $this->hasMany(SocialAccount::class);
    }

    public function deletionRequests()
    {
        return $this->hasMany(AccountDeletionRequest::class);
    }

    public function isOnline(): bool
    {
        return $this->last_seen_at !== null && $this->last_seen_at->greaterThanOrEqualTo(now()->subMinutes(2));
    }

    public function ensureUsername(): string
    {
        if (!empty($this->username)) {
            return $this->username;
        }

        $base = preg_replace('/[^a-zA-Z0-9_]/', '', strtolower($this->name ?? ''));
        if (strlen($base) < 3) {
            $base = 'player';
        }
        $base = substr($base, 0, 18);
        $candidate = $base . '_' . $this->id;
        $suffix = 1;
        while (static::where('username', $candidate)->where('id', '!=', $this->id)->exists()) {
            $candidate = $base . '_' . $this->id . '_' . $suffix;
            $suffix++;
        }

        $this->username = $candidate;
        $this->saveQuietly();
        return $this->username;
    }
}
