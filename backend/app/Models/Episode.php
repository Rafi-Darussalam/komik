<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Episode extends Model
{
    protected $fillable = ['comic_id', 'title', 'chapter_number', 'content'];

    public function comic(): BelongsTo
    {
        return $this->belongsTo(Comic::class);
    }
}
