import { Link } from 'react-router-dom'
import Container from './Container'
import Logo from './Logo'

// lucide-react no longer ships brand/social icons, so simple inline
// glyphs are used here instead.
const FacebookIcon = (props) => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" {...props}>
    <path d="M13.5 21v-7.5H16l.5-3H13.5V8.5c0-.9.3-1.5 1.7-1.5H16.5V4.3C16.1 4.2 15 4 13.7 4c-2.6 0-4.3 1.6-4.3 4.5V10.5H7v3h2.4V21h3.1Z" />
  </svg>
)
const InstagramIcon = (props) => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="1.8" {...props}>
    <rect x="3.5" y="3.5" width="17" height="17" rx="5" />
    <circle cx="12" cy="12" r="4.2" />
    <circle cx="17.2" cy="6.8" r="1.1" fill="currentColor" stroke="none" />
  </svg>
)
const TwitterIcon = (props) => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" {...props}>
    <path d="M20 6.4c-.6.3-1.3.5-2 .6a3.5 3.5 0 0 0 1.5-1.9c-.7.4-1.5.7-2.3.9a3.5 3.5 0 0 0-6 3.2A9.9 9.9 0 0 1 3.9 5.6a3.5 3.5 0 0 0 1.1 4.7c-.6 0-1.1-.2-1.6-.4v.1c0 1.7 1.2 3.1 2.8 3.4-.5.1-1 .2-1.6.1.4 1.4 1.7 2.4 3.3 2.5A7 7 0 0 1 3 17.5a9.9 9.9 0 0 0 5.4 1.6c6.5 0 10-5.4 10-10v-.5c.7-.5 1.3-1.1 1.6-1.8Z" />
  </svg>
)
const LinkedinIcon = (props) => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" {...props}>
    <path d="M6.9 8.4H3.6V20h3.3V8.4ZM5.3 3.5a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8ZM20.4 20h-3.3v-6.1c0-1.5-.5-2.4-1.7-2.4-1 0-1.6.7-1.8 1.3-.1.2-.1.6-.1.9V20H10s.1-10.6 0-11.6h3.3v1.6c.4-.7 1.2-1.7 3-1.7 2.2 0 3.9 1.5 3.9 4.6V20Z" />
  </svg>
)

const columns = [
  {
    title: 'Company',
    links: [
      { label: 'Home', to: '/' },
      { label: 'About Us', to: '/about' },
      { label: 'Privacy Policy', to: '/privacy-policy' },
    ],
  },
  {
    title: 'Legal',
    links: [
      { label: 'Terms & Conditions', to: '/terms' },
      { label: 'Refund Policy', to: '/refund-policy' },
      { label: 'Delete Account', to: '/delete-account' },
    ],
  },
  {
    title: 'Support',
    links: [{ label: 'Contact Us', to: '/contact' }],
  },
]

const socials = [FacebookIcon, InstagramIcon, TwitterIcon, LinkedinIcon]

export default function Footer() {
  return (
    <footer className="border-t border-navy-100 bg-navy-900">
      <Container className="grid grid-cols-1 gap-10 py-16 md:grid-cols-[1.4fr_1fr_1fr_1fr]">
        <div>
          <Logo light />
          <p className="mt-4 max-w-xs text-[15px] leading-relaxed text-navy-100/70">
            Community-powered logistics connecting delivery requesters with
            travelers.
          </p>
          <div className="mt-6 flex gap-3">
            {socials.map((Icon, i) => (
              <a
                key={i}
                href="#"
                aria-label="Social link"
                className="grid h-9 w-9 place-items-center rounded-full bg-white/5 text-white/70 transition-colors hover:bg-brand-500 hover:text-white"
              >
                <Icon size={16} />
              </a>
            ))}
          </div>
        </div>

        {columns.map((col) => (
          <div key={col.title}>
            <h4 className="text-sm font-semibold uppercase tracking-wide text-white/50">
              {col.title}
            </h4>
            <ul className="mt-4 space-y-3">
              {col.links.map((link) => (
                <li key={link.label}>
                  <Link
                    to={link.to}
                    className="text-[15px] text-navy-100/80 transition-colors hover:text-brand-400"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </Container>

      <div className="border-t border-white/10">
        <Container className="py-6 text-center text-sm text-white/40">
          © {new Date().getFullYear()} BazzarGo. All Rights Reserved.
        </Container>
      </div>
    </footer>
  )
}
