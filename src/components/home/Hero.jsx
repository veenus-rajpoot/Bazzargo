import { ArrowRight, MapPin, ShieldCheck, Package } from 'lucide-react'
import Container from '../Container'
import Button from '../Button'
import Eyebrow from '../Eyebrow'

export default function Hero() {
  return (
    <section className="relative overflow-hidden bg-navy-900">
      {/* ambient background */}
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute -top-32 -right-24 h-[420px] w-[420px] rounded-full bg-brand-500/25 blur-[110px]" />
        <div className="absolute bottom-0 left-[-10%] h-[320px] w-[320px] rounded-full bg-teal-500/15 blur-[100px]" />
      </div>

      <Container className="relative grid grid-cols-1 items-center gap-14 py-20 md:py-28 lg:grid-cols-2 lg:gap-10">
        <div>
          <Eyebrow light>Community-Powered Logistics</Eyebrow>

          <h1 className="mt-6 font-display text-[38px] font-extrabold leading-[1.08] tracking-tight text-white sm:text-[46px] lg:text-[54px]">
            Travel Together.
            <br />
            Deliver <span className="text-brand-400">Smarter.</span>
          </h1>

          <p className="mt-6 max-w-lg text-[17px] leading-relaxed text-navy-100/70">
            BazzarGo connects delivery requesters with travelers who have
            unused travel capacity — matched by route, verified with OTP, and
            secured with KYC and encrypted payments.
          </p>

          <div className="mt-9 flex flex-wrap items-center gap-4">
            <Button href="#" size="lg">
              Download App <ArrowRight size={18} />
            </Button>
            <Button to="/contact" variant="outlineLight" size="lg">
              Contact Us
            </Button>
          </div>

          <div className="mt-12 flex flex-wrap gap-x-8 gap-y-4 text-sm text-navy-100/60">
            <div className="flex items-center gap-2">
              <ShieldCheck size={16} className="text-brand-400" /> KYC Verified
            </div>
            <div className="flex items-center gap-2">
              <MapPin size={16} className="text-brand-400" /> Route Matched
            </div>
            <div className="flex items-center gap-2">
              <Package size={16} className="text-brand-400" /> OTP Secured
            </div>
          </div>
        </div>

        <div className="relative mx-auto w-full max-w-md lg:max-w-none">
          <div className="relative rounded-[28px] border border-white/10 bg-white/[0.04] p-6 shadow-2xl backdrop-blur-sm">
            <div className="rounded-2xl bg-navy-800/80 p-5">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold uppercase tracking-wide text-white/40">
                  Live Match
                </span>
                <span className="rounded-full bg-teal-500/20 px-2.5 py-1 text-xs font-semibold text-teal-400">
                  In Transit
                </span>
              </div>

              <div className="mt-5 flex items-center gap-3">
                <div className="flex flex-col items-center">
                  <span className="h-2.5 w-2.5 rounded-full bg-brand-500" />
                  <span className="my-1 h-10 w-px border-l border-dashed border-white/25" />
                  <span className="h-2.5 w-2.5 rounded-full bg-teal-500" />
                </div>
                <div className="flex-1 space-y-4">
                  <div>
                    <p className="text-sm font-semibold text-white">Jaipur</p>
                    <p className="text-xs text-white/40">Pickup · OTP 4821</p>
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-white">Udaipur</p>
                    <p className="text-xs text-white/40">Drop-off · ETA 3h 40m</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="mt-4 grid grid-cols-2 gap-3">
              <div className="rounded-xl bg-navy-800/80 p-4">
                <p className="text-2xl font-extrabold text-white">12,400+</p>
                <p className="mt-1 text-xs text-white/40">Deliveries matched</p>
              </div>
              <div className="rounded-xl bg-navy-800/80 p-4">
                <p className="text-2xl font-extrabold text-white">4.8★</p>
                <p className="mt-1 text-xs text-white/40">Average rating</p>
              </div>
            </div>
          </div>
        </div>
      </Container>
    </section>
  )
}
