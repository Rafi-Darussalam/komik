<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Panel extends Model
{
    protected $fillable = ['episode_id', 'image_path', 'sort_order'];

    public function episode()
    {
        return $this->belongsTo(Episode::class);
    }
}
