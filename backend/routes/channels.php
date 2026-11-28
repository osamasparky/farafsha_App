<?php

use App\Models\Room;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// قناة بث أحداث الغرفة التفاعلية (مقيدة بأعضاء الغرفة)
Broadcast::channel('room.{code}', function ($user = null, $code = null) {
    if (!$user || !$code) {
        return false;
    }
    return Room::where('code', $code)
        ->where(function ($q) use ($user) {
            $q->where('host_user_id', $user->id)
              ->orWhereHas('players', fn ($pq) => $pq->where('user_id', $user->id));
        })
        ->exists();
});
