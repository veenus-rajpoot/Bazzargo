import Container from './Container'
import Eyebrow from './Eyebrow'

export default function PageHero({ eyebrow, title, subtitle }) {
  return (
    <section className="border-b border-navy-100 bg-navy-50 py-16 md:py-20">
      <Container className="max-w-3xl text-center">
        {eyebrow && <Eyebrow className="mx-auto">{eyebrow}</Eyebrow>}
        <h1 className="mt-5 font-display text-[30px] font-extrabold leading-tight tracking-tight text-navy-900 sm:text-[38px]">
          {title}
        </h1>
        {subtitle && (
          <p className="mx-auto mt-4 max-w-2xl text-[16.5px] leading-relaxed text-navy-400">
            {subtitle}
          </p>
        )}
      </Container>
    </section>
  )
}
