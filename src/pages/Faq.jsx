import Layout from '../components/Layout'
import Container from '../components/Container'
import PageHero from '../components/PageHero'
import FaqAccordion from '../components/FaqAccordion'
import { faqs } from '../lib/faqData'

export default function Faq() {
  return (
    <Layout>
      <PageHero title="Frequently Asked Questions" />

      <section className="py-20 md:py-24">
        <Container className="max-w-3xl">
          <p className="mb-10 text-center text-[15px] text-navy-400">
            Everything you need to know about how BazzarGo works. Can't find
            your answer?{' '}
            <a
              href="mailto:support@bazzargo.com"
              className="font-semibold text-brand-600 hover:text-brand-700"
            >
              Contact support
            </a>
            .
          </p>
          <FaqAccordion items={faqs} defaultOpenIndex={0} />
        </Container>
      </section>
    </Layout>
  )
}
