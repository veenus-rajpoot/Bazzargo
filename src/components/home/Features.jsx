import {
  Route,
  Radar,
  Lock,
  KeyRound,
  UserCheck,
  Star,
  MessageCircle,
  Bell,
  Wallet,
} from 'lucide-react'
import Container from '../Container'

const features = [
  { icon: Route, title: 'Smart Route Matching', desc: 'Matches delivery requests to travelers heading the same way.' },
  { icon: Radar, title: 'Live Tracking', desc: 'Follow your parcel in real time from pickup to drop-off.' },
  { icon: Lock, title: 'Secure Payments', desc: 'Encrypted, PCI-compliant payment processing on every transaction.' },
  { icon: KeyRound, title: 'OTP Verification', desc: 'Two-step OTP confirms every pickup and delivery.' },
  { icon: UserCheck, title: 'KYC Verification', desc: 'Every traveler and requester is identity-verified.' },
  { icon: Star, title: 'Ratings & Reviews', desc: 'Build trust through community feedback after every delivery.' },
  { icon: MessageCircle, title: 'Real-time Chat', desc: 'Coordinate pickup and drop-off details directly in-app.' },
  { icon: Bell, title: 'Notifications', desc: 'Stay updated at every stage of your delivery journey.' },
  { icon: Wallet, title: 'Earn While Traveling', desc: 'Turn your everyday trips into a source of extra income.' },
]

export default function Features() {
  return (
    <section className="bg-navy-50 py-20 md:py-24">
      <Container>
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-display text-[28px] font-extrabold tracking-tight text-navy-900 sm:text-[34px]">
            Everything You Need, Built In
          </h2>
        </div>

        <div className="mt-14 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {features.map(({ icon: Icon, title, desc }) => (
            <div
              key={title}
              className="group rounded-2xl border border-navy-100 bg-white p-6 shadow-card transition-all duration-200 hover:-translate-y-0.5 hover:shadow-card-hover"
            >
              <div className="grid h-11 w-11 place-items-center rounded-xl bg-brand-500 text-white transition-transform duration-200 group-hover:scale-105">
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
