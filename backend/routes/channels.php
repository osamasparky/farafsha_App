<?php

use App\Models\Room;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// قناة بث أحداث الغرفة التفاعلية
Broadcast::channel('room.{code}', function ($user = null, $code = null) {
    return true;
});
