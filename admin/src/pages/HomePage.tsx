import { useEffect, useState } from "react";
import { adminApi } from "@/lib/api";
import { Users, BookOpen, ShieldCheck, Loader2 } from "lucide-react";
import { 
  Card, 
  CardContent, 
  CardDescription, 
  CardHeader, 
  CardTitle 
} from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts';

export function HomePage() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await adminApi.getStats();
        setStats(response.data);
      } catch (error) {
        console.error("Failed to fetch stats:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchStats();
  }, []);

  if (loading) {
    return (
      <div className="flex h-[80vh] items-center justify-center">
        <div className="flex flex-col items-center gap-2">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
          <p className="text-muted-foreground">Memuat dashboard analitik...</p>
        </div>
      </div>
    );
  }

  const COLORS = ['#8884d8', '#82ca9d', '#ffc658', '#ff8042'];

  const roleData = [
    { name: 'User Biasa', value: stats?.total_users || 0 },
    { name: 'Administrator', value: stats?.total_admins || 0 },
  ];

  const comicStatusData = stats?.comic_stats?.map((item: any) => ({
    name: item.status,
    value: item.total
  })) || [];

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">Dashboard Overview</h2>
        <p className="text-muted-foreground mt-2">
          Selamat datang kembali. Berikut adalah ringkasan data platform komik Anda saat ini.
        </p>
      </div>

      {/* STAT CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="shadow-sm transition-shadow hover:shadow-md">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground uppercase">
              Total Komik
            </CardTitle>
            <div className="p-2 bg-blue-100 rounded-lg text-blue-600">
              <BookOpen size={18} />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{stats?.total_comics || 0}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Seluruh judul komik terdaftar
            </p>
          </CardContent>
        </Card>
        
        <Card className="shadow-sm transition-shadow hover:shadow-md">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground uppercase">
              Total Pengguna
            </CardTitle>
            <div className="p-2 bg-green-100 rounded-lg text-green-600">
              <Users size={18} />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{stats?.total_users || 0}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Pengguna aktif non-admin
            </p>
          </CardContent>
        </Card>

        <Card className="shadow-sm transition-shadow hover:shadow-md">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground uppercase">
              Total Admin
            </CardTitle>
            <div className="p-2 bg-purple-100 rounded-lg text-purple-600">
              <ShieldCheck size={18} />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{stats?.total_admins || 0}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Staf pengelola platform
            </p>
          </CardContent>
        </Card>
      </div>

      {/* CHARTS */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="shadow-sm">
          <CardHeader>
            <CardTitle>Distribusi Komik (Status)</CardTitle>
            <CardDescription>Perbandingan jumlah komik berdasarkan status saat ini.</CardDescription>
          </CardHeader>
          <CardContent className="h-[300px]">
            {comicStatusData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={comicStatusData} margin={{ top: 20, right: 30, left: 0, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="name" stroke="var(--muted-foreground)" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis allowDecimals={false} stroke="var(--muted-foreground)" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip 
                    formatter={(value: number) => [value, "Total Komik"]}
                    cursor={{ fill: 'var(--muted)' }} 
                    contentStyle={{ 
                      backgroundColor: 'var(--popover)', 
                      color: 'var(--popover-foreground)',
                      borderColor: 'var(--border)',
                      borderRadius: '0.5rem',
                      boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)'
                    }}
                    itemStyle={{ color: 'var(--foreground)' }}
                  />
                  <Bar dataKey="value" fill="#8884d8" radius={[4, 4, 0, 0]} maxBarSize={60} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-muted-foreground">Belum ada data</div>
            )}
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardHeader>
            <CardTitle>Distribusi Pengguna</CardTitle>
            <CardDescription>Rasio pengguna biasa dibandingkan dengan administrator.</CardDescription>
          </CardHeader>
          <CardContent className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={roleData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={5}
                  dataKey="value"
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                >
                  {roleData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip 
                  formatter={(value: number) => [value, "Jumlah"]}
                  contentStyle={{ 
                    backgroundColor: 'var(--popover)', 
                    color: 'var(--popover-foreground)',
                    borderColor: 'var(--border)',
                    borderRadius: '0.5rem',
                    boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)'
                  }}
                  itemStyle={{ color: 'var(--foreground)' }}
                />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* RECENT ACTIVITIES */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <Card className="shadow-sm">
          <CardHeader>
            <CardTitle>Pendaftar Baru</CardTitle>
            <CardDescription>5 pengguna terakhir yang mendaftar ke platform.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-6">
              {stats?.recent_users?.map((user: any) => (
                <div key={user.id} className="flex items-center gap-4">
                  <Avatar className="h-10 w-10 border">
                    <AvatarImage src={user.profile_photo_url} />
                    <AvatarFallback className="bg-primary/10 text-primary">
                      {user.name.substring(0, 2).toUpperCase()}
                    </AvatarFallback>
                  </Avatar>
                  <div className="flex-1 space-y-1">
                    <p className="text-sm font-medium leading-none">{user.name}</p>
                    <p className="text-sm text-muted-foreground">{user.email}</p>
                  </div>
                  <div className="text-xs text-muted-foreground">
                    {new Date(user.created_at).toLocaleDateString()}
                  </div>
                </div>
              ))}
              {(!stats?.recent_users || stats.recent_users.length === 0) && (
                <div className="text-center text-muted-foreground py-4">Belum ada pengguna</div>
              )}
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardHeader>
            <CardTitle>Komik Terkini</CardTitle>
            <CardDescription>5 judul komik yang baru saja diunggah.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-6">
              {stats?.recent_comics?.map((comic: any) => (
                <div key={comic.id} className="flex items-center gap-4">
                  <div className="h-12 w-10 bg-muted rounded overflow-hidden border flex-shrink-0">
                    {comic.cover_url ? (
                      <img src={comic.cover_url} alt={comic.title} className="h-full w-full object-cover" />
                    ) : (
                      <div className="h-full w-full flex items-center justify-center text-[8px] text-muted-foreground">No img</div>
                    )}
                  </div>
                  <div className="flex-1 space-y-1 overflow-hidden">
                    <p className="text-sm font-medium leading-none line-clamp-1">{comic.title}</p>
                    <p className="text-sm text-muted-foreground line-clamp-1">{comic.author || "Unknown"}</p>
                  </div>
                  <Badge variant={comic.status === 'Ongoing' ? 'default' : 'secondary'} className="whitespace-nowrap">
                    {comic.status}
                  </Badge>
                </div>
              ))}
              {(!stats?.recent_comics || stats.recent_comics.length === 0) && (
                <div className="text-center text-muted-foreground py-4">Belum ada komik</div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

    </div>
  );
}
