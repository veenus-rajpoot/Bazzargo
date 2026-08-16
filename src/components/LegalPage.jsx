import Layout from './Layout'
import Container from './Container'
import PageHero from './PageHero'

export default function LegalPage({ title, updated, children }) {
  return (
    <Layout>
      <PageHero title={title} subtitle={updated ? `Last updated ${updated}` : undefined} />
      <section className="py-16 md:py-20">
        <Container className="max-w-3xl">
          <div className="space-y-8 text-[15.5px] leading-relaxed text-navy-500 [&_h2]:font-display [&_h2]:text-[20px] [&_h2]:font-bold [&_h2]:text-navy-900 [&_h2]:mb-3 [&_ul]:list-disc [&_ul]:pl-5 [&_ul]:space-y-1.5">
            {children}
          </div>
        </Container>
      </section>
    </Layout>
  )
}
