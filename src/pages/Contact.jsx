import { useState } from 'react'
import Layout from '../components/Layout'
import Container from '../components/Container'
import PageHero from '../components/PageHero'
import Button from '../components/Button'
import { Mail, Building2, MapPin, Send } from 'lucide-react'

const inputCls =
  'w-full rounded-xl border border-navy-100 bg-white px-4 py-3 text-[15px] text-navy-900 placeholder:text-navy-400/60 transition-colors focus:border-brand-400 focus:outline-none focus:ring-4 focus:ring-brand-100'

export default function Contact() {
  const [submitted, setSubmitted] = useState(false)
  const [form, setForm] = useState({
    name: '',
    email: '',
    phone: '',
    subject: '',
    message: '',
    honeypot: '',
  })

  function update(field) {
    return (e) => setForm((f) => ({ ...f, [field]: e.target.value }))
  }

  function handleSubmit(e) {
    e.preventDefault()
    if (form.honeypot) return // bot trap, silently ignore
    // In production this posts to a Supabase table / edge function.
    setSubmitted(true)
  }

  return (
    <Layout>
      <PageHero
        eyebrow="Get in Touch"
        title="Contact Us"
        subtitle="Have a question, partnership idea, or need support? Reach out and our team will get back to you shortly."
      />

      <section className="py-20 md:py-24">
        <Container>
          <div className="grid grid-cols-1 gap-12 lg:grid-cols-[1.3fr_1fr]">
            <div className="rounded-2xl border border-navy-100 p-7 shadow-card sm:p-9">
              {submitted ? (
                <div className="py-10 text-center">
                  <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-brand-50 text-brand-600">
                    <Send size={22} />
                  </div>
                  <h3 className="mt-5 text-[19px] font-bold text-navy-900">
                    Message sent
                  </h3>
                  <p className="mt-2 text-[15px] text-navy-400">
                    Thanks for reaching out — our team will get back to you
                    shortly.
                  </p>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-5">
                  {/* Honeypot field — hidden from real users */}
                  <div className="hidden" aria-hidden="true">
                    <label htmlFor="honeypot">
                      Don't fill this out if you're human
                    </label>
                    <input
                      id="honeypot"
                      name="honeypot"
                      type="text"
                      tabIndex={-1}
                      autoComplete="off"
                      value={form.honeypot}
                      onChange={update('honeypot')}
                    />
                  </div>

                  <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                    <div>
                      <label className="mb-1.5 block text-sm font-semibold text-navy-800">
                        Name
                      </label>
                      <input
                        required
                        className={inputCls}
                        placeholder="Your full name"
                        value={form.name}
                        onChange={update('name')}
                      />
                    </div>
                    <div>
                      <label className="mb-1.5 block text-sm font-semibold text-navy-800">
                        Email
                      </label>
                      <input
                        required
                        type="email"
                        className={inputCls}
                        placeholder="you@example.com"
                        value={form.email}
                        onChange={update('email')}
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                    <div>
                      <label className="mb-1.5 block text-sm font-semibold text-navy-800">
                        Phone
                      </label>
                      <input
                        className={inputCls}
                        placeholder="+91 98765 43210"
                        value={form.phone}
                        onChange={update('phone')}
                      />
                    </div>
                    <div>
                      <label className="mb-1.5 block text-sm font-semibold text-navy-800">
                        Subject
                      </label>
                      <input
                        required
                        className={inputCls}
                        placeholder="How can we help?"
                        value={form.subject}
                        onChange={update('subject')}
                      />
                    </div>
                  </div>

                  <div>
                    <label className="mb-1.5 block text-sm font-semibold text-navy-800">
                      Message
                    </label>
                    <textarea
                      required
                      rows={5}
                      className={`${inputCls} resize-none`}
                      placeholder="Tell us more..."
                      value={form.message}
                      onChange={update('message')}
                    />
                  </div>

                  <Button type="submit" className="w-full sm:w-auto">
                    Send Message
                  </Button>
                </form>
              )}
            </div>

            <div className="space-y-6">
              <div className="rounded-2xl border border-navy-100 p-6 shadow-card">
                <div className="flex items-start gap-4">
                  <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-600">
                    <Mail size={19} />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-navy-800">
                      Support Email
                    </p>
                    <a
                      href="mailto:support@bazzargo.com"
                      className="text-[15px] text-navy-400 hover:text-brand-600"
                    >
                      support@bazzargo.com
                    </a>
                  </div>
                </div>
              </div>

              <div className="rounded-2xl border border-navy-100 p-6 shadow-card">
                <div className="flex items-start gap-4">
                  <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-600">
                    <Building2 size={19} />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-navy-800">
                      Business Email
                    </p>
                    <a
                      href="mailto:hello@bazzargo.com"
                      className="text-[15px] text-navy-400 hover:text-brand-600"
                    >
                      hello@bazzargo.com
                    </a>
                  </div>
                </div>
              </div>

              <div className="rounded-2xl border border-navy-100 p-6 shadow-card">
                <div className="flex items-start gap-4">
                  <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-600">
                    <Building2 size={19} />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-navy-800">
                      Company
                    </p>
                    <p className="text-[15px] text-navy-400">BazzarGo</p>
                  </div>
                </div>
              </div>

              <div className="flex h-40 items-center justify-center rounded-2xl border border-dashed border-navy-100 bg-navy-50 text-sm text-navy-400">
                <div className="flex items-center gap-2">
                  <MapPin size={16} /> Map preview unavailable
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>
    </Layout>
  )
}
