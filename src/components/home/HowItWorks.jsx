import { PackagePlus, Plane, Route, ShieldCheck } from 'lucide-react'
import Container from '../Container'

const steps = [
  {
    step: 'STEP 1',
    icon: PackagePlus,
    title: 'Create a Delivery Request',
    desc: 'Requesters post what needs to be delivered, from where, to where, and by when.',
  },
  {
    step: 'STEP 2',
    icon: Plane,
    title: 'Traveler Posts Journey',
    desc: 'Travelers share their upcoming trips and available capacity along their route.',
  },
  {
    step: 'STEP 3',
    icon: Route,
    title: 'Smart Route Matching',
    desc: 'Our algorithm matches requests with travelers heading the same way, at the right time.',
  },
  {
    step: 'STEP 4',
    icon: ShieldCheck,
    title: 'Secure Delivery with OTP',
    desc: 'Pickup and drop-off are both confirmed with OTP verification for full accountability.',
  },
]

export default function HowItWorks() {
  return (
    <section className="py-20 md:py-24">
      <Container>
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-display text-[28px] font-extrabold tracking-tight text-navy-900 sm:text-[34px]">
            How It Works
          </h2>
        </div>

        <div className="relative mt-16 grid grid-cols-1 gap-10 sm:grid-cols-2 lg:grid-cols-4">
          <div className="absolute left-0 right-0 top-[26px] hidden h-px bg-navy-100 lg:block" />
          {steps.map(({ step, icon: Icon, title, desc }, i) => (
            <div key={step} className="relative">
              <div className="relative z-10 grid h-[52px] w-[52px] place-items-center rounded-2xl bg-navy-900 text-white shadow-card">
                <Icon size={22} />
              </div>
              <p className="mt-5 text-xs font-bold tracking-wider text-brand-500">
                {step}
              </p>
              <h3 className="mt-1.5 text-[17px] font-bold text-navy-900">
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
