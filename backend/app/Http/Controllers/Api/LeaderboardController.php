<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LeaderboardController extends Controller
{
    /**
     * قائمة الشرف والترتيب (أسبوعي، شهري، كل الوقت)
     */
    public function index(Request $request): JsonResponse
    {
        $timeframe = $request->query('timeframe', 'this_week'); // this_week, this_month, all_time

        $topUsers = User::orderBy('total_score', 'desc')
            ->limit(10)
            ->get(['id', 'name', 'avatar', 'level', 'total_score', 'wins_count']);

        return response()->json([
            'status' => 'success',
            'timeframe' => $timeframe,
            'leaderboard' => $topUsers,
        ]);
    }
}
