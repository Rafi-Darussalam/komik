import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { Toaster } from "@/components/ui/sonner";
import { LoginForm } from "./components/LoginForm";
import { HomePage } from "./pages/HomePage";
import { ComicManagementPage } from "./pages/ComicManagementPage";
import { UserManagementPage } from "./pages/UserManagementPage";
import { NotificationManagementPage } from "./pages/NotificationManagementPage";
import { AdminLayout } from "./components/AdminLayout";
import { TooltipProvider } from "./components/ui/tooltip";
import { ThemeProvider } from "./components/theme-provider";

function App() {
  const isAuthenticated = !!localStorage.getItem("auth_token");

  return (
    <ThemeProvider defaultTheme="light" storageKey="admin-theme">
      <BrowserRouter>
        <TooltipProvider>
        <Routes>
          <Route path="/login" element={<LoginForm />} />

          {/* Protected Routes */}
          <Route
            path="/"
            element={
              isAuthenticated ? (
                <AdminLayout>
                  <HomePage />
                </AdminLayout>
              ) : (
                <Navigate to="/login" />
              )
            }
          />
          <Route
            path="/comics"
            element={
              isAuthenticated ? (
                <AdminLayout>
                  <ComicManagementPage />
                </AdminLayout>
              ) : (
                <Navigate to="/login" />
              )
            }
          />
          <Route
            path="/users"
            element={
              isAuthenticated ? (
                <AdminLayout>
                  <UserManagementPage />
                </AdminLayout>
              ) : (
                <Navigate to="/login" />
              )
            }
          />
          <Route
            path="/notifications"
            element={
              isAuthenticated ? (
                <AdminLayout>
                  <NotificationManagementPage />
                </AdminLayout>
              ) : (
                <Navigate to="/login" />
              )
            }
          />

          {/* Catch all redirect to login or home */}
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
        <Toaster />
      </TooltipProvider>
    </BrowserRouter>
    </ThemeProvider>
  );
}

export default App;
