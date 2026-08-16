export default function Eyebrow({ children, light = false, className = '' }) {
  return (
    <span
      className={`inline-flex items-center gap-2 rounded-full px-4 py-1.5 text-[13px] font-semibold tracking-wide ${
        light
          ? 'bg-white/10 text-brand-300'
          : 'bg-brand-50 text-brand-600'
      } ${className}`}
    >
      <span className="h-1.5 w-1.5 rounded-full bg-current" />
      {children}
    </span>
  )
}
