import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import AppLayout from './app/layouts/AppLayout';
import ProtectedRoute from './shared/components/ProtectedRoute';
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
            <Route path="/applications" element={<ApplicationsPage />} />
            <Route path="/students"     element={<StudentsPage />} />
            <Route path="/programs"     element={<ProgramsPage />} />
            <Route path="/messaging"    element={<MessagingPage />} />
            <Route path="/reporting"    element={<ReportingPage />} />
            <Route path="/settings"     element={<SettingsPage />} />
            <Route path="/team"         element={<TeamPage />} />
          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  );
}