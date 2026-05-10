import React, { useEffect, useState, useMemo } from "react";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { 
  Loader2, 
  Trash2,
  BellRing,
  Send,
  Search,
  Settings2,
  MoreVertical
} from "lucide-react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { 
  Dialog, 
  DialogContent, 
  DialogDescription, 
  DialogFooter, 
  DialogHeader, 
  DialogTitle, 
  DialogTrigger 
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { 
  flexRender, 
  getCoreRowModel, 
  useReactTable, 
  getPaginationRowModel,
  getSortedRowModel,
  getFilteredRowModel,
} from "@tanstack/react-table";
import type {
  ColumnDef,
  SortingState,
  VisibilityState,
} from "@tanstack/react-table";
import { adminApi } from "@/lib/api";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";

interface NotificationData {
  id: number;
  title: string;
  message: string;
  user_id: number | null;
  expires_at: string | null;
  created_at: string;
}

export function NotificationManagementPage() {
  const [notifications, setNotifications] = useState<NotificationData[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Table states
  const [sorting, setSorting] = useState<SortingState>([]);
  const [globalFilter, setGlobalFilter] = useState("");
  const [columnVisibility, setColumnVisibility] = useState<VisibilityState>({});
  
  // Dialog & Form states
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isDeleteAlertOpen, setIsDeleteAlertOpen] = useState(false);
  const [selectedNotif, setSelectedNotif] = useState<NotificationData | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [formData, setFormData] = useState({
    title: "",
    message: "",
    user_id: "",
    expires_in_hours: "",
  });

  const fetchNotifications = async () => {
    try {
      setLoading(true);
      const response = await adminApi.getNotifications();
      setNotifications(response.data.data);
    } catch (error) {
      console.error("Failed to fetch notifications:", error);
      toast.error("Gagal memuat data notifikasi");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
  }, []);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const resetForm = () => {
    setFormData({
      title: "",
      message: "",
      user_id: "",
      expires_in_hours: "",
    });
  };

  const handleCreateNotification = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setIsSubmitting(true);
      const payload: any = {
        title: formData.title,
        message: formData.message,
      };
      if (formData.user_id) payload.user_id = formData.user_id;
      if (formData.expires_in_hours) payload.expires_in_hours = formData.expires_in_hours;

      await adminApi.createNotification(payload);
      toast.success("Notifikasi berhasil dikirim");
      setIsCreateOpen(false);
      resetForm();
      fetchNotifications();
    } catch (error: any) {
      console.error("Failed to send notification:", error);
      toast.error(error.response?.data?.message || "Gagal mengirim notifikasi.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const confirmDelete = (notif: NotificationData) => {
    setSelectedNotif(notif);
    setIsDeleteAlertOpen(true);
  };

  const handleDeleteNotification = async () => {
    if (!selectedNotif) return;
    try {
      setIsSubmitting(true);
      await adminApi.deleteNotification(selectedNotif.id);
      toast.success("Notifikasi berhasil dihapus");
      setIsDeleteAlertOpen(false);
      setSelectedNotif(null);
      fetchNotifications();
    } catch (error) {
      console.error("Failed to delete notification:", error);
      toast.error("Gagal menghapus notifikasi");
    } finally {
      setIsSubmitting(false);
    }
  };

  const isExpired = (expiresAt: string | null) => {
    if (!expiresAt) return false;
    return new Date(expiresAt).getTime() < new Date().getTime();
  };

  // TanStack Table Columns
  const columns = useMemo<ColumnDef<NotificationData>[]>(() => [
    {
      accessorKey: "title",
      header: () => <div className="pl-4">Notifikasi</div>,
      cell: ({ row }) => {
        const notif = row.original;
        return (
          <div className="pl-4 flex items-start gap-3">
            <div className="mt-1 bg-primary/10 p-2 rounded-full shrink-0">
              <BellRing className="w-4 h-4 text-primary" />
            </div>
            <div className="flex flex-col max-w-[250px] md:max-w-[400px]">
              <span className="font-semibold line-clamp-1">{notif.title}</span>
              <span className="text-xs text-muted-foreground line-clamp-2" title={notif.message}>
                {notif.message}
              </span>
            </div>
          </div>
        );
      },
      // Include message in filtering along with title
      filterFn: (row, id, value) => {
        const title = (row.getValue(id) as string)?.toLowerCase() || "";
        const message = (row.original.message as string)?.toLowerCase() || "";
        const search = value.toLowerCase();
        return title.includes(search) || message.includes(search);
      },
    },
    {
      accessorKey: "user_id",
      header: "Target",
      cell: ({ row }) => {
        const userId = row.getValue("user_id");
        return userId ? (
          <Badge variant="outline">User ID: {userId as number}</Badge>
        ) : (
          <Badge variant="default" className="bg-green-600 hover:bg-green-700">Broadcast</Badge>
        );
      },
    },
    {
      accessorKey: "expires_at",
      header: "Status / Expired",
      cell: ({ row }) => {
        const expiresAt = row.getValue("expires_at") as string | null;
        if (!expiresAt) {
          return <Badge variant="secondary">Selamanya</Badge>;
        }
        if (isExpired(expiresAt)) {
          return <Badge variant="destructive">Expired</Badge>;
        }
        return (
          <div className="flex flex-col text-sm">
            <span className="text-muted-foreground text-[10px]">Berakhir pada:</span>
            <span>{new Date(expiresAt).toLocaleString()}</span>
          </div>
        );
      },
    },
    {
      accessorKey: "created_at",
      header: "Dikirim",
      cell: ({ row }) => (
        <div className="text-muted-foreground text-xs">
          {new Date(row.getValue("created_at")).toLocaleString()}
        </div>
      ),
    },
    {
      id: "actions",
      enableHiding: false,
      cell: ({ row }) => {
        const notif = row.original;
        return (
          <div className="text-right pr-4">
            <Button 
              variant="destructive" 
              size="icon" 
              className="h-8 w-8"
              onClick={() => confirmDelete(notif)}
              title="Hapus Notifikasi"
            >
              <Trash2 size={14} />
            </Button>
          </div>
        );
      },
    },
  ], []);

  const table = useReactTable({
    data: notifications,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    onSortingChange: setSorting,
    onGlobalFilterChange: setGlobalFilter,
    onColumnVisibilityChange: setColumnVisibility,
    state: {
      sorting,
      globalFilter,
      columnVisibility,
    },
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Manajemen Notifikasi</h2>
          <p className="text-muted-foreground">
            Kirim dan kelola notifikasi inbox (Push Notifikasi) kepada pengguna.
          </p>
        </div>
        
        <Dialog open={isCreateOpen} onOpenChange={(open) => { setIsCreateOpen(open); if(!open) resetForm(); }}>
          <DialogTrigger asChild>
            <Button className="gap-2 w-full md:w-auto shadow-lg shadow-primary/20">
              <Send size={18} />
              Kirim Notifikasi
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-[525px]">
            <form onSubmit={handleCreateNotification}>
              <DialogHeader>
                <DialogTitle>Kirim Notifikasi Baru</DialogTitle>
                <DialogDescription>
                  Notifikasi ini akan muncul di aplikasi mobile (Kotak Masuk) pengguna.
                </DialogDescription>
              </DialogHeader>
              <div className="grid gap-4 py-4">
                <div className="grid gap-2">
                  <Label htmlFor="title">Judul Notifikasi</Label>
                  <Input 
                    id="title" 
                    name="title" 
                    placeholder="Contoh: Promo Komik Baru!" 
                    value={formData.title} 
                    onChange={handleInputChange}
                    required 
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="message">Isi Pesan</Label>
                  <Textarea 
                    id="message" 
                    name="message" 
                    rows={3}
                    placeholder="Tuliskan detail pesan notifikasi..." 
                    value={formData.message} 
                    onChange={handleInputChange}
                    required
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="user_id">Target User ID (Opsional)</Label>
                  <Input 
                    id="user_id" 
                    name="user_id" 
                    type="number"
                    placeholder="Kosongkan untuk Broadcast (semua user)" 
                    value={formData.user_id} 
                    onChange={handleInputChange}
                  />
                  <p className="text-xs text-muted-foreground">Jika dikosongkan, notifikasi akan dikirim ke semua pengguna.</p>
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="expires_in_hours">Batas Waktu (Time to Live) dalam Jam</Label>
                  <Input 
                    id="expires_in_hours" 
                    name="expires_in_hours" 
                    type="number"
                    step="0.5"
                    placeholder="Contoh: 24 (untuk 1 hari)" 
                    value={formData.expires_in_hours} 
                    onChange={handleInputChange}
                  />
                  <p className="text-xs text-muted-foreground">Kosongkan jika notifikasi berlaku selamanya (tidak pernah expired).</p>
                </div>
              </div>
              <DialogFooter>
                <Button type="button" variant="outline" onClick={() => setIsCreateOpen(false)}>
                  Batal
                </Button>
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                  Kirim Pesan
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="flex items-center gap-4 w-full md:w-auto">
          <div className="relative w-full md:w-[300px]">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Cari judul atau pesan notifikasi..."
              value={globalFilter ?? ""}
              onChange={(e) => setGlobalFilter(e.target.value)}
              className="pl-8 bg-card"
            />
          </div>
        </div>
        
        <div className="flex items-center gap-2 w-full md:w-auto">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" className="w-full md:w-auto gap-2 bg-card">
                <Settings2 size={16} />
                Columns
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-[150px]">
              {table
                .getAllColumns()
                .filter((column) => column.getCanHide())
                .map((column) => {
                  return (
                    <DropdownMenuCheckboxItem
                      key={column.id}
                      className="capitalize"
                      checked={column.getIsVisible()}
                      onCheckedChange={(value) =>
                        column.toggleVisibility(!!value)
                      }
                    >
                      {column.id === "title" ? "Notifikasi" : column.id.replace("_", " ")}
                    </DropdownMenuCheckboxItem>
                  )
                })}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

      {/* Desktop Table View */}
      <div className="hidden md:block">
        <div className="rounded-xl border bg-card shadow-sm overflow-hidden">
          <Table>
            <TableHeader>
              {table.getHeaderGroups().map((headerGroup) => (
                <TableRow key={headerGroup.id} className="bg-muted/50 hover:bg-muted/50">
                  {headerGroup.headers.map((header) => (
                    <TableHead key={header.id}>
                      {header.isPlaceholder
                        ? null
                        : flexRender(
                            header.column.columnDef.header,
                            header.getContext()
                          )}
                    </TableHead>
                  ))}
                </TableRow>
              ))}
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={table.getAllColumns().length} className="h-48 text-center">
                    <div className="flex flex-col items-center justify-center gap-2">
                      <Loader2 className="h-8 w-8 animate-spin text-primary" />
                      <span className="text-muted-foreground">Memuat data...</span>
                    </div>
                  </TableCell>
                </TableRow>
              ) : table.getRowModel().rows?.length ? (
                table.getRowModel().rows.map((row) => (
                  <TableRow
                    key={row.id}
                    data-state={row.getIsSelected() && "selected"}
                    className="group transition-colors hover:bg-muted/30"
                  >
                    {row.getVisibleCells().map((cell) => (
                      <TableCell key={cell.id}>
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={table.getAllColumns().length} className="h-48 text-center">
                    <div className="flex flex-col items-center justify-center gap-2">
                      <Search className="text-muted-foreground h-10 w-10 mb-2" />
                      <span className="text-muted-foreground font-medium">Tidak ada notifikasi ditemukan</span>
                    </div>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>
        
        {/* Pagination & Rows Per Page */}
        <div className="flex items-center justify-end space-x-2 py-4">
          <div className="flex items-center space-x-6 lg:space-x-8">
            <div className="flex items-center space-x-2">
              <p className="text-sm font-medium">Rows per page</p>
              <Select
                value={`${table.getState().pagination.pageSize}`}
                onValueChange={(value) => {
                  table.setPageSize(Number(value))
                }}
              >
                <SelectTrigger className="h-8 w-[70px]">
                  <SelectValue placeholder={table.getState().pagination.pageSize} />
                </SelectTrigger>
                <SelectContent side="top">
                  {[10, 20, 30, 40, 50].map((pageSize) => (
                    <SelectItem key={pageSize} value={`${pageSize}`}>
                      {pageSize}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex w-[100px] items-center justify-center text-sm font-medium">
              Page {table.getState().pagination.pageIndex + 1} of{" "}
              {table.getPageCount() || 1}
            </div>
            <div className="flex items-center space-x-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => table.previousPage()}
                disabled={!table.getCanPreviousPage()}
              >
                Previous
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => table.nextPage()}
                disabled={!table.getCanNextPage()}
              >
                Next
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* Mobile Card View */}
      <div className="md:hidden space-y-4">
        {loading ? (
          <div className="flex flex-col items-center justify-center h-48 gap-2">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
            <span className="text-muted-foreground">Memuat data...</span>
          </div>
        ) : table.getRowModel().rows?.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-48 gap-2 text-center p-4">
            <Search className="text-muted-foreground h-10 w-10 mb-2" />
            <span className="text-muted-foreground font-medium">Tidak ada notifikasi ditemukan</span>
          </div>
        ) : (
          table.getRowModel().rows.map((row) => {
            const notif = row.original;
            return (
              <Card key={notif.id} className="p-4 shadow-sm">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-start gap-3">
                    <div className="bg-primary/10 p-2 rounded-full shrink-0">
                      <BellRing className="w-4 h-4 text-primary" />
                    </div>
                    <div className="flex flex-col">
                      <span className="font-bold text-sm leading-tight">{notif.title}</span>
                      <span className="text-xs text-muted-foreground mt-1 line-clamp-2">{notif.message}</span>
                    </div>
                  </div>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="icon" className="h-8 w-8 shrink-0 -mt-1 -mr-1">
                        <MoreVertical size={16} />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem onClick={() => confirmDelete(notif)} className="text-destructive focus:bg-destructive/10 focus:text-destructive">
                        <Trash2 size={14} className="mr-2" />
                        Hapus
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
                
                <div className="flex justify-between items-end mt-2 pt-2 border-t border-dashed">
                  <div className="space-y-1.5">
                    {notif.user_id ? (
                      <Badge variant="outline" className="text-[9px]">User ID: {notif.user_id}</Badge>
                    ) : (
                      <Badge variant="default" className="bg-green-600 hover:bg-green-700 text-[9px]">Broadcast</Badge>
                    )}
                    
                    <div>
                      {!notif.expires_at ? (
                        <Badge variant="secondary" className="text-[9px]">Selamanya</Badge>
                      ) : isExpired(notif.expires_at) ? (
                        <Badge variant="destructive" className="text-[9px]">Expired</Badge>
                      ) : (
                        <span className="text-[10px] text-muted-foreground block">
                          S/d: {new Date(notif.expires_at).toLocaleDateString()}
                        </span>
                      )}
                    </div>
                  </div>
                  <span className="text-[10px] text-muted-foreground">
                    {new Date(notif.created_at).toLocaleDateString()}
                  </span>
                </div>
              </Card>
            );
          })
        )}
        
        {/* Mobile Pagination */}
        <div className="flex items-center justify-between py-2 border-t border-dashed">
          <div className="text-xs text-muted-foreground font-medium">
            Hal {table.getState().pagination.pageIndex + 1} dr {table.getPageCount() || 1}
          </div>
          <div className="flex items-center space-x-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => table.previousPage()}
              disabled={!table.getCanPreviousPage()}
              className="h-8 px-3"
            >
              Prev
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => table.nextPage()}
              disabled={!table.getCanNextPage()}
              className="h-8 px-3"
            >
              Next
            </Button>
          </div>
        </div>
      </div>

      {/* Delete Confirmation Alert */}
      <AlertDialog open={isDeleteAlertOpen} onOpenChange={setIsDeleteAlertOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Hapus Notifikasi</AlertDialogTitle>
            <AlertDialogDescription>
              Tindakan ini tidak dapat dibatalkan. Notifikasi akan ditarik dan tidak akan muncul lagi di aplikasi pengguna.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={isSubmitting}>Batal</AlertDialogCancel>
            <AlertDialogAction onClick={(e) => { e.preventDefault(); handleDeleteNotification(); }} className="bg-destructive text-destructive-foreground hover:bg-destructive/90" disabled={isSubmitting}>
              {isSubmitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Trash2 className="mr-2 h-4 w-4" />}
              Hapus
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
