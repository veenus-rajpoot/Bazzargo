import { ArrowRight } from 'lucide-react'
import { Link } from 'react-router-dom'
import Container from '../Container'
import FaqAccordion from '../FaqAccordion'
import { faqs } from '../../lib/faqData'

export default function FaqPreview() {
  return (
    <section className="py-20 md:py-24">
      <Container className="max-w-3xl">
        <div className="text-center">
          <h2 className="font-display text-[28px] font-extrabold tracking-tight text-navy-900 sm:text-[34px]">
            Frequently Asked Questions
          </h2>
        </div>

        <div className="mt-12">
          <FaqAccordion items={faqs} />
        </div>

        <div className="mt-8 text-center">
          <Link
            to="/faq"
            className="inline-flex items-center gap-1.5 text-[15px] font-semibold text-brand-600 hover:text-brand-700"
          >
            View all FAQs <ArrowRight size={16} />
          </Link>
        </div>
      </Container>
    </section>
  )
}
