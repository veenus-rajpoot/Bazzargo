import { ArrowRight } from 'lucide-react'
import Container from '../Container'
import Eyebrow from '../Eyebrow'
import { Link } from 'react-router-dom'

export default function AboutIntro() {
  return (
    <section className="py-20 md:py-24">
      <Container className="max-w-3xl text-center">
        <Eyebrow className="mx-auto">About BazzarGo</Eyebrow>
        <h2 className="mt-5 font-display text-[28px] font-extrabold leading-tight tracking-tight text-navy-900 sm:text-[34px]">
          Community-powered logistics for a faster, more connected India.
        </h2>
        <p className="mx-auto mt-5 max-w-2xl text-[17px] leading-relaxed text-navy-400">
          BazzarGo connects everyday travelers with people who need something
          delivered, turning unused travel capacity into a reliable,
          affordable delivery network.
        </p>
        <Link
          to="/about"
          className="mt-6 inline-flex items-center gap-1.5 text-[15px] font-semibold text-brand-600 hover:text-brand-700"
        >
          Learn more about us <ArrowRight size={16} />
        </Link>
      </Container>
    </section>
  )
}
