import Layout from '../components/Layout'
import Container from '../components/Container'
import Button from '../components/Button'

export default function NotFound() {
  return (
    <Layout>
      <Container className="flex min-h-[60vh] flex-col items-center justify-center py-24 text-center">
        <p className="font-display text-[64px] font-extrabold text-brand-500">
          404
        </p>
        <h1 className="mt-2 text-[22px] font-bold text-navy-900">
          Page not found
        </h1>
        <p className="mt-2 max-w-sm text-[15px] text-navy-400">
          The page you're looking for doesn't exist or may have moved.
        </p>
        <Button to="/" className="mt-8">
          Back to Home
        </Button>
      </Container>
    </Layout>
  )
}
