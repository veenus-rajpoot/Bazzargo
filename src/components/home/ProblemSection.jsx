import { Clock, Luggage, MapPinOff, Building2 } from 'lucide-react'
import Container from '../Container'

const problems = [
  {
    icon: Clock,
    title: 'Slow, Expensive Couriers',
    desc: 'Traditional courier networks are often costly and take days for routes that a traveler could cover in hours.',
  },
  {
    icon: Luggage,
    title: 'Wasted Travel Capacity',
    desc: 'Millions of trips happen every day with unused luggage space that never generates any value.',
  },
  {
    icon: MapPinOff,
    title: 'Unreliable Timelines',
    desc: 'Delivery windows are frequently missed, with little visibility into where a parcel actually is.',
  },
  {
    icon: Building2,
    title: 'Limited Reach',
    desc: 'Smaller towns and villages are often underserved by conventional logistics networks.',
  },
]

export default function ProblemSection() {
  return (
    <section className="bg-navy-50 py-20 md:py-24">
      <Container>
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-display text-[28px] font-extrabold tracking-tight text-navy-900 sm:text-[34px]">
            The Problem We Solve
          </h2>
          <p className="mt-4 text-[17px] leading-relaxed text-navy-400">
            Traditional delivery networks weren't built for how India
            actually moves.
          </p>
        </div>

        <div className="mt-14 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {problems.map(({ icon: Icon, title, desc }) => (
            <div
              key={title}
              className="rounded-2xl border border-navy-100 bg-white p-6 shadow-card transition-shadow duration-200 hover:shadow-card-hover"
            >
              <div className="grid h-11 w-11 place-items-center rounded-xl bg-brand-50 text-brand-600">
                <Icon size={20} />
              </div>
              <h3 className="mt-5 text-[17px] font-bold text-navy-900">
                {title}
              </h3>
              <p className="mt-2 text-[14.5px] leading-relaxed text-navy-400">
                {desc}
              </p>
            </div>
          ))}
        </div>
      </Container>
    </section>
  )
}
