import { Link } from 'react-router-dom'

const base =
  'inline-flex items-center justify-center gap-2 rounded-full font-semibold text-[15px] transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500 disabled:opacity-50 disabled:pointer-events-none'

const variants = {
  primary:
    'bg-brand-500 text-white shadow-[0_8px_20px_-6px_rgba(255,107,44,0.55)] hover:bg-brand-600 hover:shadow-[0_10px_24px_-6px_rgba(255,107,44,0.65)] active:bg-brand-700',
  secondary:
    'bg-white text-navy-800 border border-navy-100 hover:border-navy-400/40 hover:bg-navy-50',
  outlineLight:
    'bg-transparent text-white border border-white/35 hover:bg-white/10',
  ghost: 'bg-transparent text-navy-800 hover:bg-navy-50',
}

const sizes = {
  md: 'px-6 py-3',
  lg: 'px-7 py-3.5 text-base',
  sm: 'px-4 py-2 text-sm',
}

export default function Button({
  as,
  to,
  href,
  variant = 'primary',
  size = 'md',
  className = '',
  children,
  ...props
}) {
  const cls = `${base} ${variants[variant]} ${sizes[size]} ${className}`

  if (to) {
    return (
      <Link to={to} className={cls} {...props}>
        {children}
      </Link>
    )
  }
  if (href) {
    return (
      <a href={href} className={cls} {...props}>
        {children}
      </a>
    )
  }
  return (
    <button className={cls} {...props}>
      {children}
    </button>
  )
}
