import Layout from '../components/Layout'
import Hero from '../components/home/Hero'
import AboutIntro from '../components/home/AboutIntro'
import ProblemSection from '../components/home/ProblemSection'
import HowItWorks from '../components/home/HowItWorks'
import Features from '../components/home/Features'
import WhyChoose from '../components/home/WhyChoose'
import SecuritySection from '../components/home/SecuritySection'
import TechStack from '../components/home/TechStack'
import FaqPreview from '../components/home/FaqPreview'
import CtaBanner from '../components/home/CtaBanner'

export default function Home() {
  return (
    <Layout>
      <Hero />
      <AboutIntro />
      <ProblemSection />
      <HowItWorks />
      <Features />
      <WhyChoose />
      <SecuritySection />
      <TechStack />
      <FaqPreview />
      <CtaBanner />
    </Layout>
  )
}
