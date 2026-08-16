import Layout from '../components/Layout'
import Container from '../components/Container'
import PageHero from '../components/PageHero'
import { Target, Eye, GraduationCap } from 'lucide-react'

export default function About() {
  return (
    <Layout>
      <PageHero
        eyebrow="About BazzarGo"
        title="Building trust between travelers and the people who need something delivered."
      />

      <section className="py-20 md:py-24">
        <Container className="max-w-3xl">
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div className="rounded-2xl border border-navy-100 p-7 shadow-card">
              <div className="grid h-11 w-11 place-items-center rounded-xl bg-brand-50 text-brand-600">
                <Target size={20} />
              </div>
              <h2 className="mt-5 text-[19px] font-bold text-navy-900">
                Our Mission
              </h2>
              <p className="mt-2 text-[15px] leading-relaxed text-navy-400">
                Build India's largest trusted community logistics network —
                one where every unused seat in a car, train berth, or flight
                bag becomes a reliable delivery route.
              </p>
            </div>

            <div className="rounded-2xl border border-navy-100 p-7 shadow-card">
              <div className="grid h-11 w-11 place-items-center rounded-xl bg-brand-50 text-brand-600">
                <Eye size={20} />
              </div>
              <h2 className="mt-5 text-[19px] font-bold text-navy-900">
                Our Vision
              </h2>
              <p className="mt-2 text-[15px] leading-relaxed text-navy-400">
                Make parcel transportation affordable and accessible for
                every city and village in India, powered by everyday
                travelers and verified trust.
              </p>
            </div>
          </div>

          <div className="mt-16">
            <h2 className="font-display text-[24px] font-extrabold tracking-tight text-navy-900">
              Our Story
            </h2>
            <p className="mt-4 text-[16px] leading-relaxed text-navy-500">
              BazzarGo began with a simple observation: millions of people
              travel across Indian cities every day with spare luggage
              capacity, while small parcels sit stranded because traditional
              courier networks are slow, expensive, or simply don't reach the
              last mile in time. We set out to connect these two worlds —
              delivery requesters who need something moved quickly, and
              travelers who are already headed that way. What started as a
              small idea has grown into a community-first logistics platform
              built on smart route matching, verified identities, and
              secure, transparent payments.
            </p>
            <p className="mt-4 text-[16px] leading-relaxed text-navy-500">
              Today, BazzarGo is working toward a future where sending a
              parcel is as easy as booking a ride — fast, affordable, and
              backed by a trusted community of verified travelers.
            </p>
          </div>

          <div className="mt-16 rounded-2xl border border-navy-100 p-8 shadow-card sm:p-10">
            <h2 className="font-display text-[22px] font-extrabold tracking-tight text-navy-900">
              Founder
            </h2>
            <div className="mt-6 flex flex-col items-start gap-6 sm:flex-row sm:items-center">
              <div className="grid h-20 w-20 shrink-0 place-items-center rounded-full bg-navy-900 text-white">
                <GraduationCap size={28} />
              </div>
              <div>
                <h3 className="text-[18px] font-bold text-navy-900">
                  Veenus Rajpoot
                </h3>
                <p className="mt-0.5 text-[14px] font-medium text-brand-600">
                  Founder &amp; CEO, Graduate — IIT Bombay
                </p>
                <p className="mt-3 text-[15px] leading-relaxed text-navy-400">
                  Veenus founded BazzarGo with a vision to solve last-mile
                  logistics through community trust rather than heavy
                  infrastructure. Drawing on a strong engineering background
                  from IIT Bombay, he's focused on building a platform where
                  technology, safety, and everyday people come together to
                  move things smarter.
                </p>
              </div>
            </div>
          </div>
        </Container>
      </section>
    </Layout>
  )
}
