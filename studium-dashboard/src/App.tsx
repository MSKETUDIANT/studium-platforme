import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import AppLayout from './app/layouts/AppLayout';
import ProtectedRoute from './shared/components/ProtectedRoute';
import RequireRole from './shared/components/RequireRole';
import LoginPage from './features/auth/pages/LoginPage';
import ForgotPasswordPage from './features/auth/pages/ForgotPasswordPage';
import ResetPasswordPage from './features/auth/pages/ResetPasswordPage';
import StudentsPage from './features/students/pages/StudentsPage';
import ProgramsPage from './features/programs/pages/ProgramsPage';
import ApplicationsPage from './features/applications/pages/ApplicationsPage';
import MessagingPage from './features/messaging/pages/MessagingPage';
import ReportingPage from './features/reporting/pages/ReportingPage';
import SettingsPage from './features/settings/pages/SettingsPage';
import TeamPage from './features/settings/pages/TeamPage';
import AuditPage from './features/audit/pages/AuditPage';
import TasksPage from './features/tasks/pages/TasksPage';
import NotificationsPage from './features/notifications/pages/NotificationsPage';
import AmbassadorDashboardPage from './features/ambassadors/pages/AmbassadorDashboardPage';
import CommissionsAdminPage from './features/ambassadors/pages/CommissionsAdminPage';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Pages publiques */}
        <Route path="/login"           element={<LoginPage />} />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/reset-password"  element={<ResetPasswordPage />} />

        <Route element={<ProtectedRoute />}>
          <Route element={<AppLayout />}>
            <Route index element={<Navigate to="/applications" replace />} />

            {/* Tous les rôles internes */}
            <Route path="/applications"  element={<ApplicationsPage />} />
            <Route path="/students"      element={<StudentsPage />} />
            <Route path="/programs"      element={<ProgramsPage />} />
            <Route path="/tasks"         element={<TasksPage />} />
            <Route path="/notifications" element={<NotificationsPage />} />

            {/* Messagerie : admin, manager, support — pas admissions (B8 CDC) */}
            <Route element={<RequireRole roles={['admin', 'manager', 'support']} />}>
              <Route path="/messaging" element={<MessagingPage />} />
            </Route>

            {/* Rapports : admin, manager uniquement (B9 CDC) */}
            <Route element={<RequireRole roles={['admin', 'manager']} />}>
              <Route path="/reporting" element={<ReportingPage />} />
            </Route>

            {/* Configuration : admin uniquement (B1/B10 CDC) */}
            <Route element={<RequireRole roles={['admin']} />}>
              <Route path="/settings" element={<SettingsPage />} />
              <Route path="/audit"    element={<AuditPage />} />
              <Route path="/team"     element={<TeamPage />} />
            </Route>

            {/* Commissions ambassadeurs : admin, manager — B10 CDC */}
            <Route element={<RequireRole roles={['admin', 'manager']} />}>
              <Route path="/commissions" element={<CommissionsAdminPage />} />
            </Route>

            {/* Espace ambassadeur — EPIC 10 CDC */}
            <Route element={<RequireRole roles={['ambassador']} />}>
              <Route path="/ambassador" element={<AmbassadorDashboardPage />} />
            </Route>

          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  );
}