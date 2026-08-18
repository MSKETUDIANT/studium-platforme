export type RawReferralStatus = 'clicked' | 'registered' | 'converted';
export type RawCommissionStatus = 'pending' | 'payable' | 'paid';

export const REFERRAL_STATUS_LABELS: Record<RawReferralStatus, string> = {
  clicked:    'Lien cliqué',
  registered: 'Inscrit',
  converted:  'Converti',
};

export const COMMISSION_STATUS_LABELS: Record<RawCommissionStatus, string> = {
  pending: 'En cours',
  payable: 'Payable',
  paid:    'Payée',
};

export interface Referral {
  id:                     string;
  ambassadorUserId:       string;
  studentUserId:          string;
  status:                 RawReferralStatus;
  studentName:            string;
  createdAt:              string;
  convertedAt:            string | null;
}

export interface Commission {
  id:               string;
  ambassadorUserId: string;
  ambassadorName:   string;
  amount:           number;
  status:           RawCommissionStatus;
  periodStart:      string | null;
  periodEnd:        string | null;
  paidAt:           string | null;
}
