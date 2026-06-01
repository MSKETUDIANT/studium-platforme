export type RawStatus =
  | 'draft'
  | 'submitted'
  | 'needsfix'
  | 'verified'
  | 'sent'
  | 'accepted'
  | 'rejected'
  | 'pending_decision'
  | 'archived';

export type UIStatus = 'En attente' | 'Validé' | 'Urgent' | 'Refusé';

export const STATUS_MAP: Record<string, UIStatus> = {
  draft:            'En attente',
  submitted:        'En attente',
  needsfix:         'Urgent',
  verified:         'Validé',
  sent:             'Validé',
  accepted:         'Validé',
  rejected:         'Refusé',
  pending_decision: 'En attente',
  archived:         'Refusé',
};

export const RAW_STATUS_LABELS: Record<RawStatus, string> = {
  draft:            'Brouillon',
  submitted:        'Soumise',
  needsfix:         'Correction requise',
  verified:         'Vérifiée',
  sent:             'Envoyée',
  accepted:         'Acceptée',
  rejected:         'Refusée',
  pending_decision: 'En attente décision',
  archived:         'Archivée',
};

export interface Application {
  id:             string;
  studentId:      string;
  programId:      string;
  rawStatus:      RawStatus;
  status:         UIStatus;
  student:        string;
  email:          string;
  university:     string;
  program:        string;
  country:        string;
  level:          string;
  date:           string;
  score:          number;
  notes?:         string;
  contactEmail?:  string;
}

// Kanban column definitions
export const KANBAN_COLUMNS: { id: string; label: string; statuses: RawStatus[]; target: RawStatus }[] = [
  { id: 'received',   label: 'Reçues',      statuses: ['draft', 'submitted', 'pending_decision'], target: 'submitted' },
  { id: 'correction', label: 'Correction',  statuses: ['needsfix'],                               target: 'needsfix'  },
  { id: 'verified',   label: 'Vérifiées',   statuses: ['verified'],                               target: 'verified'  },
  { id: 'sent',       label: 'Envoyées',    statuses: ['sent'],                                   target: 'sent'      },
  { id: 'accepted',   label: 'Acceptées',   statuses: ['accepted'],                               target: 'accepted'  },
  { id: 'rejected',   label: 'Refusées',    statuses: ['rejected', 'archived'],                   target: 'rejected'  },
];
