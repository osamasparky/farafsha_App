<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Crew;
use App\Models\CrewMember;
use App\Models\Friendship;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class SocialController extends Controller
{

    /**
     * تحديث حالة الاتصال والغرفة الحالية للاعب
     * POST /api/social/presence
     */
    public function presence(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->ensureUsername();

        $validated = $request->validate([
            'current_room_code' => 'nullable|string|max:12',
        ]);

        $user->last_seen_at = now();
        if ($request->has('current_room_code')) {
            $code = trim((string) ($validated['current_room_code'] ?? ''));
            $user->current_room_code = $code !== '' ? $code : null;
        }
        $user->saveQuietly();

        return response()->json([
            'status' => 'success',
            'username' => $user->username,
            'is_online' => true,
        ]);
    }

    /**
     * تحديث @username الفريد للاعب
     * POST /api/social/username
     */
    public function updateUsername(Request $request): JsonResponse
    {
        $user = $request->user();
        $raw = ltrim(trim((string) $request->input('username', '')), '@');
        $request->merge(['username' => strtolower($raw)]);

        $validated = $request->validate([
            'username' => [
                'required',
                'string',
                'min:3',
                'max:24',
                'regex:/^[a-zA-Z0-9_]+$/',
                'unique:users,username,' . $user->id,
            ],
        ], [
            'username.regex' => 'اسم المستخدم يجب أن يحتوي على حروف إنجليزية وأرقام و _ فقط.',
            'username.unique' => 'اسم المستخدم مستخدم بالفعل، اختر اسماً آخر.',
            'username.min' => 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل.',
        ]);

        $user->username = $validated['username'];
        $user->save();

        return response()->json([
            'status' => 'success',
            'username' => $user->username,
        ]);
    }

    /**
     * البحث عن لاعبين عبر @username أو الاسم
     * GET /api/social/users/search?q=...
     */
    public function searchUsers(Request $request): JsonResponse
    {
        $me = $request->user();
        $q = ltrim(trim((string) $request->query('q', '')), '@');
        if (mb_strlen($q) < 2) {
            return response()->json(['status' => 'success', 'users' => []]);
        }

        $users = User::where('id', '!=', $me->id)
            ->where(function ($query) use ($q) {
                $query->where('username', 'like', "%{$q}%")
                    ->orWhere('name', 'like', "%{$q}%");
            })
            ->limit(20)
            ->get();

        $myRelations = Friendship::where('user_id', $me->id)
            ->orWhere('friend_id', $me->id)
            ->get();

        $results = $users->map(function (User $u) use ($me, $myRelations) {
            $rel = $myRelations->first(function ($r) use ($me, $u) {
                return ($r->user_id === $me->id && $r->friend_id === $u->id) ||
                    ($r->friend_id === $me->id && $r->user_id === $u->id);
            });

            $status = 'none';
            if ($rel) {
                if ($rel->status === 'accepted') {
                    $status = 'accepted';
                } elseif ($rel->user_id === $me->id) {
                    $status = 'pending_sent';
                } else {
                    $status = 'pending_received';
                }
            }

            $u->ensureUsername();
            return [
                'id' => $u->id,
                'name' => $u->name,
                'username' => $u->username,
                'avatar' => $u->avatar ?: 'assets/images/av-ahmed.webp',
                'level' => (int) ($u->level ?? 1),
                'total_score' => (int) ($u->total_score ?? 0),
                'weekly_score' => (int) ($u->weekly_score ?? 0),
                'is_online' => $u->isOnline(),
                'current_room_code' => $u->isOnline() ? $u->current_room_code : null,
                'friendship_status' => $status,
            ];
        });

        return response()->json([
            'status' => 'success',
            'users' => $results->values(),
        ]);
    }

    /**
     * قائمة الأصدقاء وطلبات الصداقة الواردة
     * GET /api/social/friends
     */
    public function friends(Request $request): JsonResponse
    {
        $me = $request->user();
        $me->ensureUsername();
        $me->last_seen_at = now();
        $me->saveQuietly();

        $accepted = Friendship::where('status', 'accepted')
            ->where(function ($q) use ($me) {
                $q->where('user_id', $me->id)->orWhere('friend_id', $me->id);
            })
            ->with(['user', 'friend'])
            ->get();

        $friendsList = $accepted->map(function (Friendship $f) use ($me) {
            $other = $f->user_id === $me->id ? $f->friend : $f->user;
            if (!$other) {
                return null;
            }
            $other->ensureUsername();
            return [
                'id' => $other->id,
                'name' => $other->name,
                'username' => $other->username,
                'avatar' => $other->avatar ?: 'assets/images/av-ahmed.webp',
                'level' => (int) ($other->level ?? 1),
                'total_score' => (int) ($other->total_score ?? 0),
                'weekly_score' => (int) ($other->weekly_score ?? 0),
                'is_online' => $other->isOnline(),
                'current_room_code' => $other->isOnline() ? $other->current_room_code : null,
                'last_seen_at' => $other->last_seen_at?->toIso8601String(),
            ];
        })->filter()->sortByDesc('is_online')->values();

        $pendingReceived = Friendship::where('friend_id', $me->id)
            ->where('status', 'pending')
            ->with('user')
            ->get()
            ->map(function (Friendship $f) {
                $sender = $f->user;
                if (!$sender) {
                    return null;
                }
                $sender->ensureUsername();
                return [
                    'friendship_id' => $f->id,
                    'id' => $sender->id,
                    'name' => $sender->name,
                    'username' => $sender->username,
                    'avatar' => $sender->avatar ?: 'assets/images/av-ahmed.webp',
                    'level' => (int) ($sender->level ?? 1),
                ];
            })->filter()->values();

        return response()->json([
            'status' => 'success',
            'my_username' => $me->username,
            'friends' => $friendsList,
            'pending_requests' => $pendingReceived,
        ]);
    }

    /**
     * إرسال طلب صداقة عبر @username أو friend_id
     * POST /api/social/friends/request
     */
    public function sendFriendRequest(Request $request): JsonResponse
    {
        $me = $request->user();
        $validated = $request->validate([
            'friend_id' => 'nullable|integer|exists:users,id',
            'username' => 'nullable|string',
        ]);

        $target = null;
        if (!empty($validated['friend_id'])) {
            $target = User::find($validated['friend_id']);
        } elseif (!empty($validated['username'])) {
            $clean = ltrim(trim(strtolower($validated['username'])), '@');
            $target = User::where('username', $clean)->first();
        }

        if (!$target) {
            return response()->json(['status' => 'error', 'message' => 'لم يتم العثور على هذا اللاعب.'], 404);
        }

        if ($target->id === $me->id) {
            return response()->json(['status' => 'error', 'message' => 'لا يمكنك إضافة نفسك كصديق.'], 422);
        }

        $existing = Friendship::where(function ($q) use ($me, $target) {
            $q->where('user_id', $me->id)->where('friend_id', $target->id);
        })->orWhere(function ($q) use ($me, $target) {
            $q->where('user_id', $target->id)->where('friend_id', $me->id);
        })->first();

        if ($existing) {
            if ($existing->status === 'accepted') {
                return response()->json(['status' => 'success', 'message' => 'أنتما أصدقاء بالفعل!', 'friendship_status' => 'accepted']);
            }
            if ($existing->friend_id === $me->id) {
                $existing->update(['status' => 'accepted']);
                return response()->json(['status' => 'success', 'message' => 'تم قبول طلب الصداقة بنجاح!', 'friendship_status' => 'accepted']);
            }
            return response()->json(['status' => 'success', 'message' => 'تم إرسال طلب الصداقة مسبقاً.', 'friendship_status' => 'pending_sent']);
        }

        Friendship::create([
            'user_id' => $me->id,
            'friend_id' => $target->id,
            'status' => 'pending',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => "تم إرسال طلب الصداقة إلى @{$target->ensureUsername()}",
            'friendship_status' => 'pending_sent',
        ]);
    }

    /**
     * قبول أو رفض أو إزالة صداقة
     * POST /api/social/friends/respond
     */
    public function respondFriendRequest(Request $request): JsonResponse
    {
        $me = $request->user();
        $validated = $request->validate([
            'friend_id' => 'required|integer',
            'action' => 'required|in:accept,decline,remove',
        ]);

        $rel = Friendship::where(function ($q) use ($me, $validated) {
            $q->where('user_id', $validated['friend_id'])->where('friend_id', $me->id);
        })->orWhere(function ($q) use ($me, $validated) {
            $q->where('user_id', $me->id)->where('friend_id', $validated['friend_id']);
        })->first();

        if (!$rel) {
            return response()->json(['status' => 'error', 'message' => 'الطلب غير موجود.'], 404);
        }

        if ($validated['action'] === 'accept' && $rel->friend_id === $me->id) {
            $rel->update(['status' => 'accepted']);
            return response()->json(['status' => 'success', 'message' => 'أصبحتما أصدقاء الآن! 🎉']);
        }

        $rel->delete();
        return response()->json(['status' => 'success', 'message' => 'تم تحديث قائمة الأصدقاء.']);
    }

    /**
     * لوحة الصدارة الأسبوعية بين الأصدقاء
     * GET /api/social/friends/leaderboard
     */
    public function friendsLeaderboard(Request $request): JsonResponse
    {
        $me = $request->user();
        $me->ensureUsername();

        $friendIds = Friendship::where('status', 'accepted')
            ->where(function ($q) use ($me) {
                $q->where('user_id', $me->id)->orWhere('friend_id', $me->id);
            })
            ->get()
            ->map(fn ($f) => $f->user_id === $me->id ? $f->friend_id : $f->user_id)
            ->push($me->id)
            ->unique()
            ->values();

        $users = User::whereIn('id', $friendIds)
            ->orderByDesc('weekly_score')
            ->orderByDesc('total_score')
            ->get();

        $ranked = $users->values()->map(function (User $u, int $index) use ($me) {
            $u->ensureUsername();
            return [
                'rank' => $index + 1,
                'id' => $u->id,
                'is_me' => $u->id === $me->id,
                'name' => $u->name,
                'username' => $u->username,
                'avatar' => $u->avatar ?: 'assets/images/av-ahmed.webp',
                'level' => (int) ($u->level ?? 1),
                'weekly_score' => (int) ($u->weekly_score ?? 0),
                'total_score' => (int) ($u->total_score ?? 0),
                'is_online' => $u->isOnline(),
                'current_room_code' => $u->isOnline() ? $u->current_room_code : null,
            ];
        });

        return response()->json([
            'status' => 'success',
            'rankings' => $ranked,
        ]);
    }

    /**
     * قائمة الشلل/المجموعات الخاصة باللاعب
     * GET /api/social/crews
     */
    public function crews(Request $request): JsonResponse
    {
        $me = $request->user();
        $crewIds = CrewMember::where('user_id', $me->id)->pluck('crew_id');

        $crews = Crew::whereIn('id', $crewIds)
            ->withCount('members')
            ->orderByDesc('total_score')
            ->get()
            ->map(fn (Crew $c) => [
                'id' => $c->id,
                'name' => $c->name,
                'code' => $c->code,
                'emoji' => $c->emoji,
                'badge_color' => $c->badge_color,
                'total_score' => (int) $c->total_score,
                'wins_count' => (int) $c->wins_count,
                'members_count' => (int) $c->members_count,
                'is_owner' => $c->owner_id === $me->id,
            ]);

        return response()->json([
            'status' => 'success',
            'crews' => $crews,
        ]);
    }

    /**
     * إنشاء شلة/فريق جديد
     * POST /api/social/crews
     */
    public function createCrew(Request $request): JsonResponse
    {
        $me = $request->user();
        $validated = $request->validate([
            'name' => 'required|string|min:2|max:50',
            'emoji' => 'nullable|string|max:12',
            'badge_color' => 'nullable|string|max:20',
        ]);

        do {
            $code = strtoupper(Str::random(6));
        } while (Crew::where('code', $code)->exists());

        $crew = Crew::create([
            'name' => trim($validated['name']),
            'code' => $code,
            'owner_id' => $me->id,
            'emoji' => $validated['emoji'] ?? '🔥',
            'badge_color' => $validated['badge_color'] ?? '#A35BFF',
            'total_score' => 0,
            'wins_count' => 0,
        ]);

        CrewMember::create([
            'crew_id' => $crew->id,
            'user_id' => $me->id,
            'role' => 'owner',
            'weekly_score' => 0,
        ]);

        return response()->json([
            'status' => 'success',
            'crew' => [
                'id' => $crew->id,
                'name' => $crew->name,
                'code' => $crew->code,
                'emoji' => $crew->emoji,
                'badge_color' => $crew->badge_color,
                'total_score' => 0,
                'members_count' => 1,
                'is_owner' => true,
            ],
        ], 201);
    }

    /**
     * الانضمام إلى شلة عبر الكود
     * POST /api/social/crews/join
     */
    public function joinCrew(Request $request): JsonResponse
    {
        $me = $request->user();
        $validated = $request->validate([
            'code' => 'required|string|min:4|max:10',
        ]);

        $crew = Crew::where('code', strtoupper(trim($validated['code'])))->first();
        if (!$crew) {
            return response()->json(['status' => 'error', 'message' => 'كود الشلة غير صحيح.'], 404);
        }

        CrewMember::firstOrCreate(
            ['crew_id' => $crew->id, 'user_id' => $me->id],
            ['role' => 'member', 'weekly_score' => 0]
        );

        return response()->json([
            'status' => 'success',
            'message' => "تم انضمامك إلى شلة {$crew->name} بنجاح!",
            'crew_id' => $crew->id,
        ]);
    }

    /**
     * تفاصيل الشلة وترتيب أعضائها الأسبوعي
     * GET /api/social/crews/{id}
     */
    public function crewDetails(Request $request, int $id): JsonResponse
    {
        $me = $request->user();
        $crew = Crew::findOrFail($id);

        $isMember = CrewMember::where('crew_id', $crew->id)->where('user_id', $me->id)->exists();
        if (!$isMember) {
            return response()->json(['status' => 'error', 'message' => 'لست عضواً في هذه الشلة.'], 403);
        }

        $members = CrewMember::where('crew_id', $crew->id)
            ->with('user')
            ->orderByDesc('weekly_score')
            ->get()
            ->filter(fn ($m) => $m->user !== null)
            ->values()
            ->map(function (CrewMember $m, int $index) use ($me) {
                $u = $m->user;
                $u->ensureUsername();
                return [
                    'rank' => $index + 1,
                    'id' => $u->id,
                    'is_me' => $u->id === $me->id,
                    'name' => $u->name,
                    'username' => $u->username,
                    'avatar' => $u->avatar ?: 'assets/images/av-ahmed.webp',
                    'role' => $m->role,
                    'weekly_score' => (int) $m->weekly_score,
                    'total_score' => (int) ($u->total_score ?? 0),
                    'is_online' => $u->isOnline(),
                    'current_room_code' => $u->isOnline() ? $u->current_room_code : null,
                ];
            });

        return response()->json([
            'status' => 'success',
            'crew' => [
                'id' => $crew->id,
                'name' => $crew->name,
                'code' => $crew->code,
                'emoji' => $crew->emoji,
                'badge_color' => $crew->badge_color,
                'total_score' => (int) $crew->total_score,
                'wins_count' => (int) $crew->wins_count,
                'is_owner' => $crew->owner_id === $me->id,
            ],
            'members' => $members,
        ]);
    }

    /**
     * إضافة صديق مباشرة إلى الشلة
     * POST /api/social/crews/{id}/invite
     */
    public function inviteFriendToCrew(Request $request, int $id): JsonResponse
    {
        $me = $request->user();
        $crew = Crew::findOrFail($id);

        $isMember = CrewMember::where('crew_id', $crew->id)->where('user_id', $me->id)->exists();
        if (!$isMember) {
            return response()->json(['status' => 'error', 'message' => 'لست عضواً في هذه الشلة.'], 403);
        }

        $validated = $request->validate([
            'user_id' => 'required|integer|exists:users,id',
        ]);

        $targetId = (int) $validated['user_id'];
        $isFriend = Friendship::where('status', 'accepted')
            ->where(function ($q) use ($me, $targetId) {
                $q->where(function ($sub) use ($me, $targetId) {
                    $sub->where('user_id', $me->id)->where('friend_id', $targetId);
                })->orWhere(function ($sub) use ($me, $targetId) {
                    $sub->where('user_id', $targetId)->where('friend_id', $me->id);
                });
            })
            ->exists();

        if (!$isFriend) {
            return response()->json([
                'status' => 'error',
                'message' => 'يمكنك فقط إضافة أصدقائك المقبولين إلى الشلة.',
            ], 403);
        }

        CrewMember::firstOrCreate(
            ['crew_id' => $crew->id, 'user_id' => $targetId],
            ['role' => 'member', 'weekly_score' => 0]
        );

        return response()->json([
            'status' => 'success',
            'message' => 'تمت إضافة اللاعب إلى الشلة بنجاح! 🎉',
        ]);
    }
}
