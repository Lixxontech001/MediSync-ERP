import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import type { Profile, Appointment } from '@/types/database'

export interface SearchResult {
  id: string
  type: 'patient' | 'appointment' | 'doctor'
  title: string
  subtitle: string
  data: Profile | Appointment
}

export function useCommandSearch() {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<SearchResult[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault()
        setOpen(o => !o)
      }
      if (e.key === 'Escape') setOpen(false)
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [])

  useEffect(() => {
    if (!query.trim() || !open) { setResults([]); return }

    const timeout = setTimeout(async () => {
      setLoading(true)
      const [patientsRes, doctorsRes] = await Promise.all([
        supabase.from('profiles').select('*').eq('role', 'PATIENT').ilike('full_name', `%${query}%`).limit(5),
        supabase.from('profiles').select('*').in('role', ['DOCTOR', 'NURSE']).ilike('full_name', `%${query}%`).limit(3),
      ])

      const patientResults: SearchResult[] = (patientsRes.data ?? []).map(p => ({
        id: p.id, type: 'patient' as const,
        title: p.full_name, subtitle: p.email,
        data: p
      }))
      const doctorResults: SearchResult[] = (doctorsRes.data ?? []).map(d => ({
        id: d.id, type: 'doctor' as const,
        title: d.full_name, subtitle: d.specialty || d.role,
        data: d
      }))

      setResults([...patientResults, ...doctorResults])
      setLoading(false)
    }, 250)

    return () => clearTimeout(timeout)
  }, [query, open])

  return { open, setOpen, query, setQuery, results, loading }
}
