@props([
    'variant' => 'primary', // primary, secondary
    'href' => null,
    'type' => 'button',
    'class' => '',
])

@php
    $baseClasses = $variant === 'secondary' ? 'btn-game-secondary' : 'btn-game-primary';
@endphp

@if($href)
    <a href="{{ $href }}" {{ $attributes->merge(['class' => "$baseClasses $class"]) }}>
        {{ $slot }}
    </a>
@else
    <button type="{{ $type }}" {{ $attributes->merge(['class' => "$baseClasses $class"]) }}>
        {{ $slot }}
    </button>
@endif

