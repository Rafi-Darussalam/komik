<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;

class Comic extends Model
{
    protected $fillable = [
        'title',
        'author',
        'synopsis',
        'cover_url',
    ];

    public function histories(): HasMany
    {
        return $this->hasMany(History::class);
    }

    public function episodes(): HasMany
    {
        return $this->hasMany(Episode::class)->orderBy('chapter_number', 'desc');
    }
}
