import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { loginSchema, type LoginFormValues } from '@/lib/schemas';
import api from '@/lib/api';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Field, FieldLabel, FieldContent, FieldError } from '@/components/ui/field';

export function LoginForm() {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (values: LoginFormValues) => {
    setLoading(true);

    try {
      const response = await api.post('/login', values);
      const { user, access_token } = response.data;

      if (user.role !== 'admin') {
        toast.error('Akses ditolak. Hanya admin yang dapat masuk.');
        setLoading(false);
        return;
      }

      localStorage.setItem('auth_token', access_token);
      localStorage.setItem('user', JSON.stringify(user));
      
      toast.success('Login berhasil! Selamat datang kembali.');
      navigate('/');
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Terjadi kesalahan saat login.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md shadow-lg border-neutral-200">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl font-bold text-center">Admin Login</CardTitle>
          <CardDescription className="text-center">
            Masukkan email dan password admin Anda
          </CardDescription>
        </CardHeader>
        <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-6">
          <CardContent className="space-y-4">
            <Field orientation="vertical">
              <FieldLabel htmlFor="email">Email</FieldLabel>
              <FieldContent>
                <Input
                  id="email"
                  type="email"
                  placeholder="admin@example.com"
                  {...register('email')}
                  className="border-neutral-300 focus:ring-neutral-950"
                  aria-invalid={!!errors.email}
                />
                <FieldError errors={[errors.email]} />
              </FieldContent>
            </Field>

            <Field orientation="vertical">
              <FieldLabel htmlFor="password">Password</FieldLabel>
              <FieldContent>
                <Input
                  id="password"
                  type="password"
                  {...register('password')}
                  className="border-neutral-300 focus:ring-neutral-950"
                  aria-invalid={!!errors.password}
                />
                <FieldError errors={[errors.password]} />
              </FieldContent>
            </Field>
          </CardContent>
          <CardFooter>
            <Button 
              type="submit" 
              className="w-full bg-neutral-950 text-white hover:bg-neutral-800" 
              disabled={loading}
            >
              {loading ? 'Masuk...' : 'Masuk'}
            </Button>
          </CardFooter>
        </form>
      </Card>
    </div>
  );
}

