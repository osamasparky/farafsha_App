<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Game;
use App\Models\SitePage;
use App\Models\Testimonial;
use Illuminate\Http\Request;
use Illuminate\View\View;

class HomeController extends Controller
{
    public function index(Request $request): View
    {
        $page = SitePage::where('slug', 'home')->first();
        $games = Game::where('is_active', true)->orderBy('sort_order')->get();
        $testimonials = Testimonial::approved()->get();

        return view('home', compact('page', 'games', 'testimonials'));
    }
}
