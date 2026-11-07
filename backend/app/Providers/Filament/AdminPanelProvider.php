<?php

namespace App\Providers\Filament;

use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Navigation\NavigationGroup;
use Filament\Pages;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\Widgets;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->login()
            ->brandName('منصة فرفشة | إدارة المحتوى والألعاب')
            ->brandLogo(fn () => asset('assets/app_icon.png'))
            ->brandLogoHeight('2.4rem')
            ->favicon(fn () => asset('assets/app_icon.png'))
            ->colors([
                'primary' => Color::hex('#8138E8'),
                'warning' => Color::hex('#FF9850'),
                'danger' => Color::hex('#C8465B'),
                'success' => Color::hex('#2E9D7B'),
                'gray' => Color::Slate,
            ])
            ->font('Cairo')
            ->sidebarCollapsibleOnDesktop()
            ->sidebarWidth('18rem')
            ->navigationGroups([
                NavigationGroup::make()
                    ->label('الألعاب والمحتوى')
                    ->icon('heroicon-o-puzzle-piece'),
                NavigationGroup::make()
                    ->label('اللعب والمنافسات')
                    ->icon('heroicon-o-fire'),
                NavigationGroup::make()
                    ->label('اللاعبون والمجتمع')
                    ->icon('heroicon-o-user-group'),
                NavigationGroup::make()
                    ->label('التواصل والتسويق')
                    ->icon('heroicon-o-chat-bubble-bottom-center-text'),
                NavigationGroup::make()
                    ->label('موقع فرفشة والمحتوى')
                    ->icon('heroicon-o-globe-alt'),
                NavigationGroup::make()
                    ->label('الإعدادات والنظام')
                    ->icon('heroicon-o-cog-6-tooth')
                    ->collapsed(),
            ])
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\\Filament\\Pages')
            ->pages([
                Pages\Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\\Filament\\Widgets')
            ->widgets([
                \App\Filament\Widgets\StatsOverview::class,
                \App\Filament\Widgets\UserActivityChart::class,
                \App\Filament\Widgets\LatestContentWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ]);
    }
}
