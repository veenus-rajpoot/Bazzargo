import { Zap, IndianRupee, ShieldCheck, Globe2 } from 'lucide-react'
import Container from '../Container'

const points = [
  {
    icon: Zap,
    title: 'Faster than traditional courier',
    desc: 'Parcels move at the speed of everyday travel instead of waiting in a depot.',
  },
  {
    icon: IndianRupee,
    title: 'More affordable',
    desc: 'No large logistics overhead — pricing reflects a traveler already making the trip.',
  },
  {
    icon: ShieldCheck,
    title: 'Community-verified trust',
    desc: "KYC and OTP verification build accountability that traditional couriers can't match.",
  },
  {
    icon: Globe2,
    title: 'Reaches further',
    desc: 'Community travelers naturally cover routes conventional networks often skip.',
  },
]

export default function WhyChoose() {
  return (
    <section className="py-20 md:py-24">
      <Container>
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-display text-[28px] font-extrabold tracking-tight text-navy-900 sm:text-[34px]">
            Why Choose BazzarGo
          </h2>
        </div>

        <div className="mt-14 grid grid-cols-1 gap-6 sm:grid-cols-2">
          {points.map(({ icon: Icon, title, desc }) => (
            <div
              key={title}
              className="flex gap-4 rounded-2xl border border-navy-100 p-6 transition-colors hover:bg-navy-50"
            >
              <div className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-600">
                <Icon size={22} />
              </div>
              <div>
                <h3 className="text-[17px] font-bold text-navy-900">
                  {title}
                </h3>
                <p className="mt-1.5 text-[14.5px] leading-relaxed text-navy-400">
                  {desc}
                </p>
              </div>
            </div>
          ))}
        </div>
      </Container>
    </section>
  )
}
