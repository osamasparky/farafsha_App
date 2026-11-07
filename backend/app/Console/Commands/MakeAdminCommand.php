<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class MakeAdminCommand extends Command
{
    protected $signature = 'farfasha:make-admin 
                            {--email= : البريد الإلكتروني للمدير} 
                            {--name= : اسم المدير} 
                            {--password= : كلمة المرور}';

    protected $description = 'إنشاء أو ترقية حساب مدير لمنصة فرفشة ولوحة Filament';

    public function handle(): int
    {
        $email = $this->option('email') ?: env('ADMIN_EMAIL') ?: $this->ask('أدخل البريد الإلكتروني للمدير:');
        $name = $this->option('name') ?: env('ADMIN_NAME') ?: $this->ask('أدخل اسم المدير:', 'مدير فرفشة');
        $password = $this->option('password') ?: env('ADMIN_PASSWORD') ?: $this->secret('أدخل كلمة المرور:');

        if (!$email || !$password) {
            $this->error('البريد الإلكتروني وكلمة المرور مطلوبان!');
            return 1;
        }

        // التأكد من وجود أدوار النظام
        $adminRole = Role::firstOrCreate(['name' => 'مدير', 'guard_name' => 'web']);
        Role::firstOrCreate(['name' => 'محرر', 'guard_name' => 'web']);
        Role::firstOrCreate(['name' => 'كاتب', 'guard_name' => 'web']);

        $user = User::updateOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'password' => Hash::make($password),
                'is_admin' => true,
            ]
        );

        $user->assignRole($adminRole);

        $this->info("تم إنشاء / ترقية حساب المدير بنجاح: {$user->email}");
        return 0;
    }
}

