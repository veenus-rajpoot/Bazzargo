import { useEffect, useState } from 'react'
import { Link, NavLink } from 'react-router-dom'
import { Menu, X } from 'lucide-react'
import Logo from './Logo'
import Container from './Container'
import Button from './Button'

const NAV_LINKS = [
  { label: 'Home', to: '/' },
  { label: 'About', to: '/about' },
  { label: 'Contact', to: '/contact' },
  { label: 'FAQ', to: '/faq' },
]

export default function Header() {
  const [open, setOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8)
    onScroll()
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  useEffect(() => {
    setOpen(false)
  }, [])

  return (
    <header
      className={`sticky top-0 z-50 border-b transition-colors duration-200 ${
        scrolled
          ? 'border-navy-100 bg-white/90 backdrop-blur-md'
          : 'border-transparent bg-white'
      }`}
    >
      <Container className="flex h-[72px] items-center justify-between">
        <Logo />

        <nav className="hidden items-center gap-1 md:flex">
          {NAV_LINKS.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              className={({ isActive }) =>
                `rounded-full px-4 py-2 text-[15px] font-medium transition-colors ${
                  isActive
                    ? 'text-brand-600'
                    : 'text-navy-500 hover:text-navy-900'
                }`
              }
            >
              {link.label}
            </NavLink>
          ))}
        </nav>

        <div className="hidden md:block">
          <Button href="#" size="sm">
            Download App
          </Button>
        </div>

        <button
          className="grid h-10 w-10 place-items-center rounded-lg text-navy-800 md:hidden"
          aria-label={open ? 'Close menu' : 'Open menu'}
          onClick={() => setOpen((v) => !v)}
        >
          {open ? <X size={22} /> : <Menu size={22} />}
        </button>
      </Container>

      {open && (
        <div className="border-t border-navy-100 bg-white md:hidden">
          <Container className="flex flex-col gap-1 py-4">
            {NAV_LINKS.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                onClick={() => setOpen(false)}
                className={({ isActive }) =>
                  `rounded-lg px-3 py-2.5 text-[15px] font-medium ${
                    isActive ? 'bg-brand-50 text-brand-600' : 'text-navy-600'
                  }`
                }
              >
                {link.label}
              </NavLink>
            ))}
            <Link
              to="#"
              onClick={() => setOpen(false)}
              className="mt-2 rounded-full bg-brand-500 px-5 py-3 text-center text-[15px] font-semibold text-white"
            >
              Download App
            </Link>
          </Container>
        </div>
      )}
    </header>
  )
}
