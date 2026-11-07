<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WahaSession;
use App\Services\WahaClient;
use Illuminate\Http\Request;

class WahaSessionController extends Controller
{
    public function index() { return WahaSession::query()->orderBy('name')->paginate(50); }
    public function show(string $name, WahaClient $client) { return response()->json($client->session($name)); }
    public function store(Request $request, WahaClient $client)
    {
        $data = $request->validate(['name' => ['required','string','max:100','regex:/^[a-zA-Z0-9_-]+$/']]);
        $session = WahaSession::firstOrCreate(['name' => $data['name']]);
        $client->createSession($session->name, config('waha.webhook_url'), config('waha.webhook_token'));
        return response()->json($session, 201);
    }
    public function start(string $name, WahaClient $client) { abort_unless(WahaSession::where('name',$name)->exists(),404); return response()->json($client->start($name)); }
    public function stop(string $name, WahaClient $client) { abort_unless(WahaSession::where('name',$name)->exists(),404); return response()->json($client->stop($name)); }
    public function qr(string $name, WahaClient $client)
    {
        abort_unless(WahaSession::where('name',$name)->exists(),404);
        return response($client->qr($name), 200, ['Content-Type' => 'image/png', 'Cache-Control' => 'no-store, private', 'Pragma' => 'no-cache']);
    }
}
