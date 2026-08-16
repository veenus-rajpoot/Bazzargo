import { Check } from 'lucide-react'
import Container from '../Container'
import Eyebrow from '../Eyebrow'

const points = [
  'KYC verification for every user on the platform.',
  'OTP verification at pickup and drop-off.',
  'Encrypted payments end-to-end.',
  'Only verified travelers can accept deliveries.',
]

export default function SecuritySection() {
  return (
    <section className="relative overflow-hidden bg-navy-900 py-20 md:py-24">
      <div className="pointer-events-none absolute -bottom-24 -left-24 h-[360px] w-[360px] rounded-full bg-teal-500/10 blur-[110px]" />
      <Container className="relative grid grid-cols-1 items-center gap-14 lg:grid-cols-2">
        <div>
          <Eyebrow light>Security & Trust</Eyebrow>
          <h2 className="mt-5 font-display text-[28px] font-extrabold leading-tight tracking-tight text-white sm:text-[34px]">
            Built on verified identities and secure transactions.
          </h2>
          <ul className="mt-8 space-y-4">
            {points.map((p) => (
              <li key={p} className="flex items-start gap-3">
                <span className="mt-0.5 grid h-6 w-6 shrink-0 place-items-center rounded-full bg-teal-500/20 text-teal-400">
                  <Check size={14} strokeWidth={3} />
                </span>
                <span className="text-[15.5px] leading-relaxed text-navy-100/80">
                  {p}
                </span>
              </li>
            ))}
          </ul>
        </div>

        <div className="rounded-[28px] border border-white/10 bg-white/[0.04] p-8">
          <div className="grid grid-cols-2 gap-4">
            {[
              { value: '100%', label: 'KYC Verified Users' },
              { value: '2-Step', label: 'OTP Confirmation' },
              { value: 'AES-256', label: 'Payment Encryption' },
              { value: '24/7', label: 'Trust & Safety Team' },
            ].map((s) => (
              <div key={s.label} className="rounded-2xl bg-navy-800/70 p-5">
                <p className="text-2xl font-extrabold text-white">
                  {s.value}
                </p>
                <p className="mt-1 text-xs leading-snug text-white/40">
                  {s.label}
                </p>
              </div>
            ))}
          </div>
        </div>
      </Container>
    </section>
  )
}
