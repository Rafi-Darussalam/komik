<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // User::factory(10)->create();

        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
        ]);

        $comics = [
            [
                'title' => 'One Piece',
                'author' => 'Eiichiro Oda',
                'synopsis' => 'Kisah petualangan Luffy menjadi Raja Bajak Laut.',
                'cover_url' => 'https://upload.wikimedia.org/wikipedia/id/9/90/One_Piece%2C_Volume_61_Cover_%28Japanese%29.jpg',
            ],
            [
                'title' => 'Naruto',
                'author' => 'Masashi Kishimoto',
                'synopsis' => 'Kisah ninja yang bercita-cita menjadi Hokage.',
                'cover_url' => 'https://upload.wikimedia.org/wikipedia/id/9/94/NarutoCoverTankobon1.jpg',
            ],
            [
                'title' => 'Solo Leveling',
                'author' => 'Chugong',
                'synopsis' => 'Dari hunter terlemah menjadi hunter terkuat di dunia.',
                'cover_url' => 'https://upload.wikimedia.org/wikipedia/en/1/14/Solo_Leveling_Webtoon.png',
            ],
        ];

        foreach ($comics as $c) {
            $comic = \App\Models\Comic::create($c);
            
            // Seed 2 episodes for each comic
            \App\Models\Episode::create([
                'comic_id' => $comic->id,
                'title' => 'Episode 1: Awal Perjalanan',
                'chapter_number' => 1,
                'content' => 'Ini adalah isi konten episode pertama dari ' . $comic->title,
            ]);
            \App\Models\Episode::create([
                'comic_id' => $comic->id,
                'title' => 'Episode 2: Pertemuan Tak Terduga',
                'chapter_number' => 2,
                'content' => 'Ini adalah isi konten episode kedua dari ' . $comic->title,
            ]);
        }
    }
}
