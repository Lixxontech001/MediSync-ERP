import { useEffect, useRef, useState } from 'react'

export interface VitalDataPoint {
  time: string
  heartRate: number
  spo2: number
  systolicBp: number
  diastolicBp: number
}

function randomInRange(min: number, max: number, prev: number, drift: number = 3) {
  const next = prev + (Math.random() - 0.5) * drift * 2
  return Math.min(max, Math.max(min, Math.round(next)))
}

export function useVitals(patientId?: string) {
  const [data, setData] = useState<VitalDataPoint[]>(() => {
    const initial: VitalDataPoint[] = []
    let hr = 72, spo2 = 98, sbp = 120, dbp = 80
    for (let i = 19; i >= 0; i--) {
      const t = new Date(Date.now() - i * 3000)
      hr = randomInRange(55, 110, hr, 4)
      spo2 = randomInRange(92, 100, spo2, 1)
      sbp = randomInRange(100, 160, sbp, 5)
      dbp = randomInRange(60, 100, dbp, 3)
      initial.push({
        time: t.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
        heartRate: hr, spo2, systolicBp: sbp, diastolicBp: dbp
      })
    }
    return initial
  })

  const latestRef = useRef(data[data.length - 1])

  useEffect(() => {
    if (!patientId) return
    const interval = setInterval(() => {
      const prev = latestRef.current
      const next: VitalDataPoint = {
        time: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
        heartRate: randomInRange(55, 110, prev.heartRate, 4),
        spo2: randomInRange(92, 100, prev.spo2, 1),
        systolicBp: randomInRange(100, 160, prev.systolicBp, 5),
        diastolicBp: randomInRange(60, 100, prev.diastolicBp, 3),
      }
      latestRef.current = next
      setData(prev => [...prev.slice(-19), next])
    }, 3000)
    return () => clearInterval(interval)
  }, [patientId])

  const latest = data[data.length - 1]

  return { data, latest }
}
