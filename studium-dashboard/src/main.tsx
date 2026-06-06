import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { initMonitoring } from './shared/services/monitoring'

initMonitoring()

createRoot(document.getElementById('root')!).render(<App />)