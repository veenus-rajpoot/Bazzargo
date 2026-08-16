import { Link } from 'react-router-dom'

export default function Logo({ light = false }) {
  return (
    <Link to="/" className="flex items-center gap-2.5 shrink-0">
      <span className="grid h-9 w-9 place-items-center rounded-[10px] bg-brand-500 text-white">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none">
          <path
            d="M4 16 L9.5 6.5 L12.5 12.5 L16 6.5 L20 16"
            stroke="currentColor"
            strokeWidth="2.4"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </span>
      <span
        className={`font-display text-[19px] font-extrabold tracking-tight ${
          light ? 'text-white' : 'text-navy-900'
        }`}
      >
        Bazzar<span className="text-brand-500">Go</span>
      </span>
    </Link>
  )
}
