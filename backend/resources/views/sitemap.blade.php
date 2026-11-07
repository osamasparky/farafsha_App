{!! '<' . '?xml version="1.0" encoding="UTF-8"?' . '>' !!}
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
    {{-- الصفحة الرئيسية --}}
    <url>
        <loc>{{ url('/') }}</loc>
        <xhtml:link rel="alternate" hreflang="ar" href="{{ url('/') }}" />
        <xhtml:link rel="alternate" hreflang="en" href="{{ url('/en') }}" />
        <changefreq>daily</changefreq>
        <priority>1.0</priority>
    </url>
    <url>
        <loc>{{ url('/en') }}</loc>
        <xhtml:link rel="alternate" hreflang="ar" href="{{ url('/') }}" />
        <xhtml:link rel="alternate" hreflang="en" href="{{ url('/en') }}" />
        <changefreq>daily</changefreq>
        <priority>0.9</priority>
    </url>

    {{-- دليل الألعاب --}}
    <url>
        <loc>{{ url('/games') }}</loc>
        <xhtml:link rel="alternate" hreflang="ar" href="{{ url('/games') }}" />
        <xhtml:link rel="alternate" hreflang="en" href="{{ url('/en/games') }}" />
        <changefreq>weekly</changefreq>
        <priority>0.9</priority>
    </url>

    {{-- لعبة الأمثال التفاعلية --}}
    <url>
        <loc>{{ url('/games/amthal') }}</loc>
        <xhtml:link rel="alternate" hreflang="ar" href="{{ url('/games/amthal') }}" />
        <xhtml:link rel="alternate" hreflang="en" href="{{ url('/en/games/amthal') }}" />
        <changefreq>weekly</changefreq>
        <priority>0.9</priority>
    </url>

    {{-- صفحة التحميل --}}
    <url>
        <loc>{{ url('/download') }}</loc>
        <xhtml:link rel="alternate" hreflang="ar" href="{{ url('/download') }}" />
        <xhtml:link rel="alternate" hreflang="en" href="{{ url('/en/download') }}" />
        <changefreq>monthly</changefreq>
        <priority>0.8</priority>
    </url>

    {{-- صفحات الألعاب الفردية --}}
    @foreach($games as $game)
        <url>
            <loc>{{ url('/games/' . $game->slug) }}</loc>
            <xhtml:link rel="alternate" hreflang="ar" href="{{ url('/games/' . $game->slug) }}" />
            <xhtml:link rel="alternate" hreflang="en" href="{{ url('/en/games/' . $game->slug) }}" />
            <lastmod>{{ $game->updated_at->toAtomString() }}</lastmod>
            <changefreq>weekly</changefreq>
            <priority>0.8</priority>
        </url>
    @endforeach

    {{-- الصفحات التعريفية والمعلوماتية --}}
    @foreach($pages as $p)
        @if($p->slug !== 'home')
            <url>
                <loc>{{ url('/' . $p->slug) }}</loc>
                <xhtml:link rel="alternate" hreflang="ar" href="{{ url('/' . $p->slug) }}" />
                <xhtml:link rel="alternate" hreflang="en" href="{{ url('/en/' . $p->slug) }}" />
                <lastmod>{{ $p->updated_at->toAtomString() }}</lastmod>
                <changefreq>monthly</changefreq>
                <priority>0.6</priority>
            </url>
        @endif
    @endforeach
</urlset>

