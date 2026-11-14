<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || !$user->is_admin) {
            return response()->json([
                'status' => 'error',
                'message' => 'غير مصرح لك بتنفيذ هذه العملية، الصلاحية مقتصرة على المشرفين فقط.',
            ], 403);
        }

        return $next($request);
    }
}
