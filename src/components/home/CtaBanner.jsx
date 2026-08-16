import Container from '../Container'
import Button from '../Button'

export default function CtaBanner() {
  return (
    <section className="py-20 md:py-24">
      <Container>
        <div className="relative overflow-hidden rounded-[32px] bg-brand-500 px-8 py-16 text-center sm:px-16">
          <div className="pointer-events-none absolute -top-16 -right-16 h-64 w-64 rounded-full bg-white/10" />
          <div className="pointer-events-none absolute -bottom-20 -left-10 h-56 w-56 rounded-full bg-white/10" />

          <h2 className="relative font-display text-[28px] font-extrabold tracking-tight text-white sm:text-[36px]">
            Join the BazzarGo community
          </h2>
          <p className="relative mx-auto mt-4 max-w-xl text-[16px] leading-relaxed text-white/85">
            Whether you need to send a parcel or want to earn from your next
            trip, BazzarGo makes it simple and secure.
          </p>
          <div className="relative mt-8 flex flex-wrap items-center justify-center gap-4">
            <Button href="#" variant="secondary" size="lg">
              Download App
            </Button>
            <Button to="/contact" variant="outlineLight" size="lg">
              Contact Us
            </Button>
          </div>
        </div>
      </Container>
    </section>
  )
}
