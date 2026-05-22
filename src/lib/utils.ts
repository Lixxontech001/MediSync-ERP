import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount)
}

export function formatDate(date: string | Date, format: 'short' | 'long' | 'time' = 'short'): string {
  const d = new Date(date)
  if (format === 'time') return d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
  if (format === 'long') return d.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

export function getPriorityColor(priority: string): string {
  const map: Record<string, string> = {
    critical: 'text-red-400 bg-red-500/10 border-red-500/30',
    high: 'text-orange-400 bg-orange-500/10 border-orange-500/30',
    medium: 'text-yellow-400 bg-yellow-500/10 border-yellow-500/30',
    low: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30',
  }
  return map[priority] ?? map.medium
}

export function getStatusColor(status: string): string {
  const map: Record<string, string> = {
    scheduled: 'text-blue-400 bg-blue-500/10 border-blue-500/30',
    confirmed: 'text-cyan-400 bg-cyan-500/10 border-cyan-500/30',
    in_progress: 'text-yellow-400 bg-yellow-500/10 border-yellow-500/30',
    completed: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30',
    cancelled: 'text-slate-400 bg-slate-500/10 border-slate-500/30',
    no_show: 'text-red-400 bg-red-500/10 border-red-500/30',
    active: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30',
    paid: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30',
    overdue: 'text-red-400 bg-red-500/10 border-red-500/30',
    draft: 'text-slate-400 bg-slate-500/10 border-slate-500/30',
    sent: 'text-blue-400 bg-blue-500/10 border-blue-500/30',
  }
  return map[status] ?? map.draft
}

export function generateInvoiceNumber(): string {
  const date = new Date()
  const year = date.getFullYear()
  const rand = Math.floor(Math.random() * 90000) + 10000
  return `INV-${year}-${rand}`
}
