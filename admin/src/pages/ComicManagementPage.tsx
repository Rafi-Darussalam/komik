import React, { useEffect, useState, useMemo } from "react";
import {
  type ColumnDef,
  type ColumnFiltersState,
  type SortingState,
  type VisibilityState,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import { 
  Dialog, 
  DialogContent, 
  DialogDescription, 
  DialogFooter, 
  DialogHeader, 
  DialogTitle, 
  DialogTrigger 
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { 
  Plus, 
  Pencil, 
  Trash2, 
  Loader2, 
  ArrowUpDown, 
  ChevronDown, 
  MoreVertical, 
  Filter, 
  Search, 
  History as HistoryIcon,
  MessageSquare,
  BookOpen,
  Image as ImageIcon,
  Upload,
  X
} from "lucide-react";
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from "@/components/ui/select";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
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
import { Card } from "@/components/ui/card";
import { adminApi } from "@/lib/api";
import { toast } from "sonner";

interface Panel {
  id: number;
  episode_id: number;
  image_path: string;
  sort_order: number;
}

interface Episode {
  id: number;
  comic_id: number;
  title: string;
  chapter_number: number;
  created_at: string;
}

interface Comic {
  id: number;
  title: string;
  author: string;
  synopsis: string;
  cover_url: string;
  status: "private" | "public";
  episodes_count?: number;
  created_at: string;
}

export function ComicManagementPage() {
  const [comics, setComics] = useState<Comic[]>([]);
  const [loading, setLoading] = useState(true);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [selectedComic, setSelectedComic] = useState<Comic | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");

  // Episode Management State
  const [episodes, setEpisodes] = useState<Episode[]>([]);
  const [loadingEpisodes, setLoadingEpisodes] = useState(false);
  const [isEpisodeDialogOpen, setIsEpisodeDialogOpen] = useState(false);
  const [selectedEpisode, setSelectedEpisode] = useState<Episode | null>(null);
  const [episodeFormData, setEpisodeFormData] = useState({
    title: "",
    chapter_number: "",
  });

  // Panel Management State
  const [panels, setPanels] = useState<Panel[]>([]);
  const [loadingPanels, setLoadingPanels] = useState(false);
  const [isPanelDialogOpen, setIsPanelDialogOpen] = useState(false);
  const [panelFiles, setPanelFiles] = useState<FileList | null>(null);

  // Table state
  const [sorting, setSorting] = useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([]);
  const [columnVisibility, setColumnVisibility] = useState<VisibilityState>({});

  // Form state
  const [formData, setFormData] = useState({
    title: "",
    author: "",
    synopsis: "",
    status: "private",
  });
  const [coverImage, setCoverImage] = useState<File | null>(null);

  const fetchComics = async () => {
    try {
      setLoading(true);
      const response = await adminApi.getComics();
      setComics(response.data.data);
    } catch (error) {
      console.error("Failed to fetch comics:", error);
      toast.error("Gagal memuat data komik");
    } finally {
      setLoading(false);
    }
  };

  const fetchEpisodes = async (comicId: number) => {
    try {
      setLoadingEpisodes(true);
      const response = await adminApi.getEpisodes(comicId);
      setEpisodes(response.data.data);
    } catch (error) {
      console.error("Failed to fetch episodes:", error);
      toast.error("Gagal memuat daftar episode");
    } finally {
      setLoadingEpisodes(false);
    }
  };

  const fetchPanels = async (episodeId: number) => {
    try {
      setLoadingPanels(true);
      const response = await adminApi.getPanels(episodeId);
      setPanels(response.data.data);
    } catch (error) {
      console.error("Failed to fetch panels:", error);
      toast.error("Gagal memuat panel");
    } finally {
      setLoadingPanels(false);
    }
  };

  useEffect(() => {
    fetchComics();
  }, []);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setCoverImage(e.target.files[0]);
    }
  };

  const resetForm = () => {
    setFormData({
      title: "",
      author: "",
      synopsis: "",
      status: "private",
    });
    setCoverImage(null);
    setSelectedComic(null);
  };

  const handleCreateComic = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setIsSubmitting(true);
      const data = new FormData();
      data.append("title", formData.title);
      data.append("author", formData.author);
      data.append("synopsis", formData.synopsis);
      data.append("status", formData.status);
      if (coverImage) {
        data.append("cover_image", coverImage);
      }

      await adminApi.createComic(data);
      toast.success("Komik berhasil ditambahkan");
      setIsCreateOpen(false);
      resetForm();
      fetchComics();
    } catch (error) {
      console.error("Failed to create comic:", error);
      toast.error("Gagal menambahkan komik. Pastikan semua field terisi.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEditClick = (comic: Comic) => {
    setSelectedComic(comic);
    setFormData({
      title: comic.title,
      author: comic.author || "",
      synopsis: comic.synopsis || "",
      status: comic.status,
    });
    setIsEditOpen(true);
  };

  const handleDetailClick = (comic: Comic) => {
    setSelectedComic(comic);
    fetchEpisodes(comic.id);
    setIsDetailOpen(true);
  };

  const handleUpdateComic = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedComic) return;

    try {
      setIsSubmitting(true);
      const data = new FormData();
      data.append("title", formData.title);
      data.append("author", formData.author);
      data.append("synopsis", formData.synopsis);
      data.append("status", formData.status);
      if (coverImage) {
        data.append("cover_image", coverImage);
      }

      await adminApi.updateComic(selectedComic.id, data);
      toast.success("Komik berhasil diperbarui");
      setIsEditOpen(false);
      resetForm();
      fetchComics();
    } catch (error) {
      console.error("Failed to update comic:", error);
      toast.error("Gagal memperbarui komik");
    } finally {
      setIsSubmitting(false);
    }
  };

  const confirmDelete = (comic: Comic) => {
    setSelectedComic(comic);
    setIsDeleteOpen(true);
  };

  const handleDeleteComic = async () => {
    if (!selectedComic) return;
    
    try {
      await adminApi.deleteComic(selectedComic.id);
      toast.success("Komik berhasil dihapus");
      setIsDeleteOpen(false);
      setSelectedComic(null);
      fetchComics();
    } catch (error) {
      console.error("Failed to delete comic:", error);
      toast.error("Gagal menghapus komik");
    }
  };

  // Episode Handlers
  const handleAddEpisode = () => {
    setSelectedEpisode(null);
    setEpisodeFormData({ title: "", chapter_number: "" });
    setIsEpisodeDialogOpen(true);
  };

  const handleEditEpisode = (episode: Episode) => {
    setSelectedEpisode(episode);
    setEpisodeFormData({ 
      title: episode.title, 
      chapter_number: episode.chapter_number.toString() 
    });
    setIsEpisodeDialogOpen(true);
  };

  const handleSaveEpisode = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedComic) return;

    try {
      setIsSubmitting(true);
      const data = {
        title: episodeFormData.title,
        chapter_number: parseFloat(episodeFormData.chapter_number),
      };

      if (selectedEpisode) {
        await adminApi.updateEpisode(selectedEpisode.id, data);
        toast.success("Episode berhasil diperbarui");
      } else {
        await adminApi.createEpisode(selectedComic.id, data);
        toast.success("Episode baru berhasil ditambahkan");
      }
      
      setIsEpisodeDialogOpen(false);
      fetchEpisodes(selectedComic.id);
    } catch (error) {
      console.error("Failed to save episode:", error);
      toast.error("Gagal menyimpan episode");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteEpisode = async (episodeId: number) => {
    if (!selectedComic) return;
    if (!confirm("Hapus episode ini?")) return;

    try {
      await adminApi.deleteEpisode(episodeId);
      toast.success("Episode berhasil dihapus");
      fetchEpisodes(selectedComic.id);
    } catch (error) {
      console.error("Failed to delete episode:", error);
      toast.error("Gagal menghapus episode");
    }
  };

  // Panel Handlers
  const handleManagePanels = (episode: Episode) => {
    setSelectedEpisode(episode);
    fetchPanels(episode.id);
    setIsPanelDialogOpen(true);
  };

  const handleUploadPanels = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedEpisode || !panelFiles) return;

    try {
      setIsSubmitting(true);
      const data = new FormData();
      for (let i = 0; i < panelFiles.length; i++) {
        data.append("images[]", panelFiles[i]);
      }

      await adminApi.createPanels(selectedEpisode.id, data);
      toast.success("Panel berhasil diunggah");
      setPanelFiles(null);
      fetchPanels(selectedEpisode.id);
    } catch (error) {
      console.error("Failed to upload panels:", error);
      toast.error("Gagal mengunggah panel");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeletePanel = async (panelId: number) => {
    if (!selectedEpisode) return;
    if (!confirm("Hapus panel ini?")) return;

    try {
      await adminApi.deletePanel(panelId);
      toast.success("Panel berhasil dihapus");
      fetchPanels(selectedEpisode.id);
    } catch (error) {
      console.error("Failed to delete panel:", error);
      toast.error("Gagal menghapus panel");
    }
  };

  // TanStack Table Columns (Memoized to prevent re-renders)
  const columns = useMemo<ColumnDef<Comic>[]>(() => [
    {
      accessorKey: "cover_url",
      header: () => <div className="pl-4">Cover</div>,
      cell: ({ row }) => (
        <div className="pl-4">
          <div className="h-14 w-10 rounded-lg overflow-hidden bg-muted border shadow-sm">
            {row.getValue("cover_url") ? (
              <img 
                src={row.getValue("cover_url") as string} 
                alt={row.original.title} 
                className="h-full w-full object-cover"
              />
            ) : (
              <div className="h-full w-full flex items-center justify-center text-[10px] text-muted-foreground">
                No img
              </div>
            )}
          </div>
        </div>
      ),
    },
    {
      accessorKey: "title",
      header: ({ column }) => {
        return (
          <Button
            variant="ghost"
            onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
            className="-ml-4"
          >
            Judul
            <ArrowUpDown className="ml-2 h-4 w-4" />
          </Button>
        )
      },
      cell: ({ row }) => <div className="font-semibold">{row.getValue("title")}</div>,
    },
    {
      accessorKey: "author",
      header: "Penulis",
      cell: ({ row }) => <div>{row.getValue("author") || "-"}</div>,
    },
    {
      accessorKey: "episodes_count",
      header: "Eps",
      cell: ({ row }) => <Badge variant="outline">{row.getValue("episodes_count") || 0}</Badge>,
    },
    {
      accessorKey: "status",
      header: "Status",
      cell: ({ row }) => (
        <Badge variant={row.getValue("status") === "public" ? "default" : "secondary"} className="capitalize">
          {row.getValue("status")}
        </Badge>
      ),
    },
    {
      accessorKey: "created_at",
      header: "Dibuat",
      cell: ({ row }) => (
        <div className="text-muted-foreground text-xs">
          {new Date(row.getValue("created_at")).toLocaleDateString()}
        </div>
      ),
    },
    {
      id: "actions",
      enableHiding: false,
      cell: ({ row }) => {
        const comic = row.original

        return (
          <div className="text-right">
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="h-8 w-8">
                  <MoreVertical size={16} />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-48">
                <DropdownMenuLabel>Opsi Komik</DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={() => handleDetailClick(comic)} className="cursor-pointer">
                  <BookOpen size={14} className="mr-2" />
                  Lihat Detail & Eps
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => handleEditClick(comic)} className="cursor-pointer">
                  <Pencil size={14} className="mr-2" />
                  Edit Komik
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={() => confirmDelete(comic)} className="cursor-pointer text-destructive focus:text-destructive">
                  <Trash2 size={14} className="mr-2" />
                  Hapus Komik
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        )
      },
    },
  ], []);

  // Memoized filtered data
  const filteredData = useMemo(() => {
    return comics.filter(c => {
      const matchesSearch = c.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
                           c.author?.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesStatus = statusFilter === "all" || c.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [comics, searchQuery, statusFilter]);

  const table = useReactTable({
    data: filteredData,
    columns,
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    onColumnVisibilityChange: setColumnVisibility,
    state: {
      sorting,
      columnFilters,
      columnVisibility,
    },
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Manajemen Komik</h2>
          <p className="text-muted-foreground">
            Kelola koleksi komik, episode, dan panel Anda di sini.
          </p>
        </div>
        <Dialog open={isCreateOpen} onOpenChange={(open) => { setIsCreateOpen(open); if(!open) resetForm(); }}>
          <DialogTrigger asChild>
            <Button className="gap-2 w-full md:w-auto shadow-lg shadow-primary/20">
              <Plus size={18} />
              Tambah Komik
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-[525px]">
            <form onSubmit={handleCreateComic}>
              <DialogHeader>
                <DialogTitle>Tambah Komik Baru</DialogTitle>
                <DialogDescription>
                  Isi detail komik baru di bawah ini.
                </DialogDescription>
              </DialogHeader>
              <div className="grid gap-4 py-4">
                <div className="grid gap-2">
                  <Label htmlFor="title">Judul</Label>
                  <Input 
                    id="title" 
                    name="title" 
                    placeholder="Masukkan judul komik" 
                    value={formData.title} 
                    onChange={handleInputChange}
                    required 
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="author">Penulis</Label>
                  <Input 
                    id="author" 
                    name="author" 
                    placeholder="Masukkan nama penulis" 
                    value={formData.author} 
                    onChange={handleInputChange}
                  />
                </div>
                <div className="grid gap-2">
                  <Label>Gambar Cover</Label>
                  <div className="flex items-center justify-center w-full">
                    <label htmlFor="cover_image" className="flex flex-col items-center justify-center w-full h-20 border-2 border-dashed rounded-lg cursor-pointer bg-muted/50 hover:bg-muted border-muted-foreground/25 hover:border-muted-foreground/50 transition-colors">
                      <div className="flex flex-col items-center justify-center py-3 text-center px-4">
                        <Upload className="w-5 h-5 mb-1 text-muted-foreground/70" />
                        <p className="text-xs text-muted-foreground">
                          <span className="font-semibold">Klik untuk unggah</span> atau drag and drop
                        </p>
                        <p className="text-[10px] text-muted-foreground/70 mt-0.5">
                          PNG, JPG atau WEBP disarankan
                        </p>
                      </div>
                      <Input 
                        id="cover_image" 
                        name="cover_image" 
                        type="file"
                        accept="image/*"
                        onChange={handleFileChange}
                        className="hidden"
                      />
                    </label>
                  </div>
                  {coverImage && (
                    <p className="text-xs text-muted-foreground truncate">
                      File terpilih: <span className="font-medium text-foreground">{coverImage.name}</span>
                    </p>
                  )}
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="status">Status</Label>
                  <Select 
                    value={formData.status} 
                    onValueChange={(val) => setFormData(prev => ({ ...prev, status: val }))}
                  >
                    <SelectTrigger id="status" className="w-full">
                      <SelectValue placeholder="Pilih status" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="private">Private (Hanya Admin)</SelectItem>
                      <SelectItem value="public">Public (Semua User)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="synopsis">Sinopsis</Label>
                  <Textarea 
                    id="synopsis" 
                    name="synopsis" 
                    placeholder="Masukkan sinopsis komik" 
                    value={formData.synopsis} 
                    onChange={handleInputChange}
                    rows={4}
                  />
                </div>
              </div>
              <DialogFooter>
                <Button type="button" variant="outline" onClick={() => setIsCreateOpen(false)}>
                  Batal
                </Button>
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                  Simpan Komik
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="flex items-center gap-4 w-full md:w-auto">
          <div className="relative w-full md:w-80">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground h-4 w-4" />
            <Input 
              placeholder="Cari judul atau penulis..." 
              className="pl-10"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <div className="w-full md:w-48">
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger>
                <div className="flex items-center gap-2">
                  <Filter size={14} className="text-muted-foreground" />
                  <SelectValue placeholder="Status" />
                </div>
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Semua Status</SelectItem>
                <SelectItem value="public">Public</SelectItem>
                <SelectItem value="private">Private</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
        <div className="flex items-center gap-2">
           <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" className="ml-auto">
                Columns <ChevronDown className="ml-2 h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
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
                      {column.id}
                    </DropdownMenuCheckboxItem>
                  )
                })}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

      {/* Edit Dialog */}
      <Dialog open={isEditOpen} onOpenChange={(open) => { setIsEditOpen(open); if(!open) resetForm(); }}>
        <DialogContent className="sm:max-w-[525px]">
          <form onSubmit={handleUpdateComic}>
            <DialogHeader>
              <DialogTitle>Edit Komik</DialogTitle>
              <DialogDescription>
                Perbarui detail komik ini. Kosongkan gambar jika tidak ingin diubah.
              </DialogDescription>
            </DialogHeader>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="edit-title">Judul</Label>
                <Input 
                  id="edit-title" 
                  name="title" 
                  value={formData.title} 
                  onChange={handleInputChange}
                  required 
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="edit-author">Penulis</Label>
                <Input 
                  id="edit-author" 
                  name="author" 
                  value={formData.author} 
                  onChange={handleInputChange}
                />
              </div>
              <div className="grid gap-2">
                <Label>Gambar Cover</Label>
                <div className="flex items-center justify-center w-full">
                  <label htmlFor="edit-cover_image" className="flex flex-col items-center justify-center w-full h-20 border-2 border-dashed rounded-lg cursor-pointer bg-muted/50 hover:bg-muted border-muted-foreground/25 hover:border-muted-foreground/50 transition-colors">
                    <div className="flex flex-col items-center justify-center py-3 text-center px-4">
                      <Upload className="w-5 h-5 mb-1 text-muted-foreground/70" />
                      <p className="text-xs text-muted-foreground">
                        <span className="font-semibold">Klik untuk unggah</span> atau drag and drop
                      </p>
                      <p className="text-[10px] text-muted-foreground/70 mt-0.5">
                        Biarkan kosong jika tidak ingin mengubah cover
                      </p>
                    </div>
                    <Input 
                      id="edit-cover_image" 
                      name="cover_image" 
                      type="file"
                      accept="image/*"
                      onChange={handleFileChange}
                      className="hidden"
                    />
                  </label>
                </div>
                {coverImage && (
                  <p className="text-xs text-muted-foreground truncate">
                    File baru terpilih: <span className="font-medium text-foreground">{coverImage.name}</span>
                  </p>
                )}
              </div>
              <div className="grid gap-2">
                <Label htmlFor="edit-status">Status</Label>
                <Select 
                  value={formData.status} 
                  onValueChange={(val) => setFormData(prev => ({ ...prev, status: val }))}
                >
                  <SelectTrigger id="edit-status" className="w-full">
                    <SelectValue placeholder="Pilih status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="private">Private</SelectItem>
                    <SelectItem value="public">Public</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="grid gap-2">
                <Label htmlFor="edit-synopsis">Sinopsis</Label>
                <Textarea 
                  id="edit-synopsis" 
                  name="synopsis" 
                  value={formData.synopsis} 
                  onChange={handleInputChange}
                  rows={4}
                />
              </div>
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setIsEditOpen(false)}>
                Batal
              </Button>
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Simpan Perubahan
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Detail & Episode Management Dialog */}
      <Dialog open={isDetailOpen} onOpenChange={setIsDetailOpen}>
        <DialogContent className="sm:max-w-[800px] max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Detail Komik & Episode</DialogTitle>
            <DialogDescription>
              Kelola episode untuk komik <strong>{selectedComic?.title}</strong>
            </DialogDescription>
          </DialogHeader>
          
          <div className="grid md:grid-cols-3 gap-6 py-4">
            <div className="space-y-4">
              <div className="aspect-[3/4] rounded-lg overflow-hidden border bg-muted shadow-sm">
                <img 
                  src={selectedComic?.cover_url} 
                  alt={selectedComic?.title} 
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="space-y-1">
                <h4 className="font-bold text-lg">{selectedComic?.title}</h4>
                <p className="text-sm text-muted-foreground">Oleh {selectedComic?.author || "Anonim"}</p>
                <Badge variant={selectedComic?.status === 'public' ? 'default' : 'secondary'}>
                  {selectedComic?.status}
                </Badge>
              </div>
              <p className="text-xs text-muted-foreground line-clamp-4">{selectedComic?.synopsis || "Tidak ada sinopsis."}</p>
            </div>

            <div className="md:col-span-2 space-y-4">
              <div className="flex justify-between items-center">
                <h5 className="font-bold">Daftar Episode</h5>
                <Button size="sm" onClick={handleAddEpisode} className="h-8 gap-1">
                  <Plus size={14} />
                  Tambah Eps
                </Button>
              </div>

              <div className="border rounded-lg overflow-hidden">
                <Table>
                  <TableHeader>
                    <TableRow className="bg-muted/50 hover:bg-muted/50">
                      <TableHead className="w-16">No.</TableHead>
                      <TableHead>Judul Episode</TableHead>
                      <TableHead className="text-right">Aksi</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {loadingEpisodes ? (
                      <TableRow>
                        <TableCell colSpan={3} className="h-24 text-center">
                          <Loader2 className="h-5 w-5 animate-spin mx-auto text-primary" />
                        </TableCell>
                      </TableRow>
                    ) : episodes.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={3} className="h-24 text-center text-muted-foreground text-sm">
                          Belum ada episode.
                        </TableCell>
                      </TableRow>
                    ) : (
                      episodes.map((ep) => (
                        <TableRow key={ep.id}>
                          <TableCell className="font-medium">#{ep.chapter_number}</TableCell>
                          <TableCell>{ep.title}</TableCell>
                          <TableCell className="text-right">
                            <div className="flex justify-end gap-2">
                              <Button variant="ghost" size="icon" className="h-7 w-7 text-primary" onClick={() => handleManagePanels(ep)} title="Kelola Panel">
                                <ImageIcon size={12} />
                              </Button>
                              <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => handleEditEpisode(ep)}>
                                <Pencil size={12} />
                              </Button>
                              <Button variant="destructive" size="icon" className="h-7 w-7" onClick={() => handleDeleteEpisode(ep.id)}>
                                <Trash2 size={12} />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </div>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Episode Create/Edit Dialog (Nested) */}
      <Dialog open={isEpisodeDialogOpen} onOpenChange={setIsEpisodeDialogOpen}>
        <DialogContent className="sm:max-w-[400px]">
          <form onSubmit={handleSaveEpisode}>
            <DialogHeader>
              <DialogTitle>{selectedEpisode ? "Edit Episode" : "Tambah Episode"}</DialogTitle>
              <DialogDescription>
                Masukkan detail episode untuk komik ini.
              </DialogDescription>
            </DialogHeader>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="ep-number">Chapter Number</Label>
                <Input 
                  id="ep-number" 
                  type="number" 
                  step="0.1"
                  placeholder="Contoh: 1" 
                  value={episodeFormData.chapter_number} 
                  onChange={(e) => setEpisodeFormData(prev => ({ ...prev, chapter_number: e.target.value }))}
                  required 
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="ep-title">Judul Episode</Label>
                <Input 
                  id="ep-title" 
                  placeholder="Masukkan judul episode" 
                  value={episodeFormData.title} 
                  onChange={(e) => setEpisodeFormData(prev => ({ ...prev, title: e.target.value }))}
                  required 
                />
              </div>
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setIsEpisodeDialogOpen(false)}>
                Batal
              </Button>
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Simpan
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Panel Management Dialog (Nested) */}
      <Dialog open={isPanelDialogOpen} onOpenChange={setIsPanelDialogOpen}>
        <DialogContent className="sm:max-w-[600px] max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Kelola Panel</DialogTitle>
            <DialogDescription>
              Episode {selectedEpisode?.chapter_number}: <strong>{selectedEpisode?.title}</strong>
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-6 py-4">
            {/* Upload Section */}
            <Card className="p-0 border-dashed bg-muted/30 overflow-hidden">
              <form onSubmit={handleUploadPanels}>
                <div className="relative flex flex-col items-center justify-center p-4 text-center cursor-pointer hover:bg-muted/50 transition-colors">
                  <Input 
                    type="file" 
                    multiple 
                    accept="image/*" 
                    onChange={(e) => setPanelFiles(e.target.files)}
                    className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                  />
                  <div className="bg-primary/10 p-2 rounded-full mb-2 text-primary">
                    <Upload size={16} />
                  </div>
                  <h4 className="font-semibold text-sm">Klik atau seret file gambar ke sini</h4>
                  <p className="text-xs text-muted-foreground mt-0.5">Mendukung banyak gambar sekaligus</p>
                  
                  {panelFiles && panelFiles.length > 0 && (
                    <div className="mt-2 px-2 py-1 bg-primary/20 text-primary-foreground text-[10px] rounded font-medium">
                      {panelFiles.length} gambar siap diunggah
                    </div>
                  )}
                </div>
                
                <div className="p-3 border-t bg-card flex justify-end">
                  <Button type="submit" disabled={!panelFiles || panelFiles.length === 0 || isSubmitting} className="gap-2 w-full sm:w-auto">
                    {isSubmitting ? <Loader2 size={16} className="animate-spin" /> : <Upload size={16} />}
                    Mulai Unggah
                  </Button>
                </div>
              </form>
            </Card>

            {/* Panel List */}
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
              {loadingPanels ? (
                <div className="col-span-full py-12 flex justify-center">
                  <Loader2 className="h-8 w-8 animate-spin text-primary" />
                </div>
              ) : panels.length === 0 ? (
                <div className="col-span-full py-12 text-center text-muted-foreground">
                  Belum ada panel. Silakan upload gambar panel komik.
                </div>
              ) : (
                panels.map((panel, idx) => (
                  <div key={panel.id} className="relative group aspect-[2/3] rounded-md overflow-hidden border bg-muted">
                    <img 
                      src={`http://localhost:8000/api/images/${panel.image_path}`} 
                      alt={`Panel ${idx + 1}`} 
                      className="w-full h-full object-cover"
                    />
                    <div className="absolute top-1 left-1 bg-black/60 text-white text-[10px] px-1.5 rounded">
                      #{idx + 1}
                    </div>
                    <Button
                      variant="destructive"
                      size="icon"
                      onClick={() => handleDeletePanel(panel.id)}
                      className="absolute top-1 right-1 h-6 w-6 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <X size={12} />
                    </Button>
                  </div>
                ))
              )}
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Delete Alert Dialog */}
      <AlertDialog open={isDeleteOpen} onOpenChange={setIsDeleteOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Hapus Komik?</AlertDialogTitle>
            <AlertDialogDescription>
              Tindakan ini tidak dapat dibatalkan. Komik <strong>{selectedComic?.title}</strong> akan dihapus permanen beserta semua data terkait.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Batal</AlertDialogCancel>
            <AlertDialogAction onClick={handleDeleteComic} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Hapus
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Desktop Table View (Shadcn Data Table) */}
      <div className="hidden md:block">
        <div className="rounded-xl border bg-card shadow-sm overflow-hidden">
          <Table>
            <TableHeader>
              {table.getHeaderGroups().map((headerGroup) => (
                <TableRow key={headerGroup.id} className="bg-muted/50 hover:bg-muted/50">
                  {headerGroup.headers.map((header) => {
                    return (
                      <TableHead key={header.id}>
                        {header.isPlaceholder
                          ? null
                          : flexRender(
                              header.column.columnDef.header,
                              header.getContext()
                            )}
                      </TableHead>
                    )
                  })}
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
                      <div className="h-12 w-12 bg-muted rounded-full flex items-center justify-center">
                        <Search className="text-muted-foreground h-6 w-6" />
                      </div>
                      <span className="text-muted-foreground font-medium">Tidak ada komik ditemukan</span>
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
              {table.getPageCount()}
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
        ) : filteredData.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-48 gap-2 text-center p-4">
            <Search className="text-muted-foreground h-10 w-10 mb-2" />
            <span className="text-muted-foreground font-medium">Tidak ada komik ditemukan</span>
          </div>
        ) : (
          filteredData.map((comic) => (
            <Card key={comic.id} className="overflow-hidden border-l-4 border-l-primary shadow-sm">
              <div className="flex h-32">
                <div className="w-24 shrink-0 bg-muted border-r">
                  {comic.cover_url ? (
                    <img 
                      src={comic.cover_url} 
                      alt={comic.title} 
                      className="h-full w-full object-cover"
                    />
                  ) : (
                    <div className="h-full w-full flex items-center justify-center text-xs text-muted-foreground">
                      No img
                    </div>
                  )}
                </div>
                <div className="flex-1 p-3 flex flex-col justify-between">
                  <div>
                    <div className="flex justify-between items-start">
                      <h3 className="font-bold line-clamp-1 text-sm">{comic.title}</h3>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon" className="h-8 w-8 -mt-1 -mr-1">
                            <MoreVertical size={16} />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem onClick={() => handleDetailClick(comic)}>
                            <BookOpen size={14} className="mr-2" />
                            Detail & Eps
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => handleEditClick(comic)}>
                            <Pencil size={14} className="mr-2" />
                            Edit
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => confirmDelete(comic)} className="text-destructive">
                            <Trash2 size={14} className="mr-2" />
                            Hapus
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                    <p className="text-[10px] text-muted-foreground line-clamp-1 mb-1">{comic.author || "Anonim"}</p>
                  </div>
                  <div className="flex justify-between items-end">
                    <div className="space-y-1">
                      <Badge variant={comic.status === "public" ? "default" : "secondary"} className="text-[9px] h-4 px-1 leading-none uppercase tracking-wider">
                        {comic.status}
                      </Badge>
                      <div className="flex items-center gap-2 text-[10px] text-muted-foreground">
                        <HistoryIcon size={10} />
                        <span>{new Date(comic.created_at).toLocaleDateString()}</span>
                      </div>
                    </div>
                    <Button variant="outline" size="sm" className="h-7 text-[10px] px-2 gap-1" onClick={() => handleDetailClick(comic)}>
                      <MessageSquare size={10} />
                      Detail
                    </Button>
                  </div>
                </div>
              </div>
            </Card>
          ))
        )}
      </div>
    </div>
  );
}
