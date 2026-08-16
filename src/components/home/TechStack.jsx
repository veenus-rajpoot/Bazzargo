import { Cloud, ShieldCheck, Cpu, Radar } from 'lucide-react'
import Container from '../Container'

const items = [
  { icon: Cloud, title: 'Secure Cloud Infra', desc: 'Reliable, scalable infrastructure behind every request.' },
  { icon: ShieldCheck, title: 'Encrypted Payments', desc: 'Every transaction protected end-to-end.' },
  { icon: Cpu, title: 'Smart Matching', desc: 'Algorithms that match routes in real time.' },
  { icon: Radar, title: 'Live Tracking', desc: 'Precise, real-time visibility into every delivery.' },
]

export default function TechStack() {
  return (
    <section className="bg-navy-50 py-20 md:py-24">
      <Container>
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-display text-[28px] font-extrabold tracking-tight text-navy-900 sm:text-[34px]">
            Technology Stack
          </h2>
          <p className="mt-4 text-[17px] leading-relaxed text-navy-400">
            Powered by real-time tracking, secure cloud infrastructure, and
            smart matching algorithms designed to move parcels efficiently.
          </p>
        </div>

        <div className="mt-14 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {items.map(({ icon: Icon, title, desc }) => (
            <div
              key={title}
              className="rounded-2xl bg-white p-6 text-center shadow-card"
            >
              <div className="mx-auto grid h-12 w-12 place-items-center rounded-full bg-brand-50 text-brand-600">
                <Icon size={22} />
              </div>
              <h3 className="mt-4 text-[16px] font-bold text-navy-900">
                {title}
              </h3>
              <p className="mt-2 text-[14px] leading-relaxed text-navy-400">
                {desc}
              </p>
            </div>
          ))}
        </div>
      </Container>
    </section>
  )
}
