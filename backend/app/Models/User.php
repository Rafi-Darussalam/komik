<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable, \Laravel\Sanctum\HasApiTokens;

    protected $fillable = [
        'name',
        'email',
        'password',
        'profile_photo',
        'role',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $appends = ['profile_photo_url'];

    public function getProfilePhotoUrlAttribute()
    {
        if ($this->profile_photo) {
            return url('api/images/' . $this->profile_photo);
        }
        return null;
    }

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function histories()
    {
        return $this->hasMany(History::class);
    }

    public function ratings()
    {
        return $this->hasMany(Rating::class);
    }

    public function bookmarks()
    {
        return $this->hasMany(Bookmark::class);
    }
}
