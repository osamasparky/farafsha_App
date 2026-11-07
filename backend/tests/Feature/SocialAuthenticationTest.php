<?php

namespace Tests\Feature;

use App\Models\SocialAccount;
use App\Models\User;
use App\Services\Auth\FacebookTokenVerifier;
use App\Services\Auth\GoogleTokenVerifier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class SocialAuthenticationTest extends TestCase
{
    use RefreshDatabase;

    public function test_unsupported_provider_returns_422(): void
    {
        $response = $this->postJson('/api/v1/auth/social/unsupported', [
            'id_token' => 'dummy',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_missing_credentials_returns_422(): void
    {
        $response = $this->postJson('/api/v1/auth/social/google', []);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_google_login_creates_new_user_and_issues_token(): void
    {
        $mockGoogle = Mockery::mock(GoogleTokenVerifier::class);
        $mockGoogle->shouldReceive('verify')->once()->with('valid-google-id-token')->andReturn([
            'provider_user_id' => 'google-user-12345',
            'email' => 'new.google.user@example.com',
            'name' => 'سارة فرفشة',
            'avatar' => 'https://example.com/avatar.jpg',
            'metadata' => ['email_verified' => true],
        ]);

        $this->app->instance(GoogleTokenVerifier::class, $mockGoogle);

        $response = $this->postJson('/api/v1/auth/social/google', [
            'id_token' => 'valid-google-id-token',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'name' => 'سارة فرفشة',
                        'email' => 'new.google.user@example.com',
                    ],
                    'token_type' => 'Bearer',
                    'is_new_user' => true,
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'new.google.user@example.com',
            'name' => 'سارة فرفشة',
        ]);

        $this->assertDatabaseHas('social_accounts', [
            'provider' => 'google',
            'provider_user_id' => 'google-user-12345',
            'provider_email' => 'new.google.user@example.com',
        ]);
    }

    public function test_facebook_login_for_existing_account(): void
    {
        $user = User::factory()->create([
            'name' => 'كريم محمود',
            'email' => 'karim@example.com',
        ]);

        SocialAccount::create([
            'user_id' => $user->id,
            'provider' => 'facebook',
            'provider_user_id' => 'fb-999888',
            'provider_email' => 'karim@example.com',
        ]);

        $mockFb = Mockery::mock(FacebookTokenVerifier::class);
        $mockFb->shouldReceive('verify')->once()->with('valid-fb-token')->andReturn([
            'provider_user_id' => 'fb-999888',
            'email' => 'karim@example.com',
            'name' => 'كريم محمود',
            'avatar' => null,
            'metadata' => ['facebook_id' => 'fb-999888'],
        ]);

        $this->app->instance(FacebookTokenVerifier::class, $mockFb);

        $response = $this->postJson('/api/v1/auth/social/facebook', [
            'access_token' => 'valid-fb-token',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'email' => 'karim@example.com',
                    ],
                    'is_new_user' => false,
                ],
            ]);
    }

    public function test_get_me_returns_profile_with_linked_providers(): void
    {
        $user = User::factory()->create();
        SocialAccount::create([
            'user_id' => $user->id,
            'provider' => 'google',
            'provider_user_id' => 'google-111',
            'provider_email' => $user->email,
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/v1/auth/me');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'linked_providers' => ['google'],
                    ],
                ],
            ]);
    }

    public function test_logout_revokes_current_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withToken($token)->postJson('/api/v1/auth/logout');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertCount(0, $user->fresh()->tokens);
    }
}

