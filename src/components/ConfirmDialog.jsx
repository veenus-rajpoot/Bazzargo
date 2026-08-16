import { AlertTriangle, X } from 'lucide-react'

export default function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  danger = false,
  loading = false,
  onConfirm,
  onCancel,
}) {
  if (!open) return null

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-navy-900/60 p-4 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
    >
      <div className="w-full max-w-md rounded-2xl bg-white p-7 shadow-2xl">
        <div className="flex items-start justify-between gap-4">
          <div
            className={`grid h-11 w-11 shrink-0 place-items-center rounded-full ${
              danger ? 'bg-red-50 text-red-600' : 'bg-brand-50 text-brand-600'
            }`}
          >
            <AlertTriangle size={20} />
          </div>
          <button
            className="grid h-8 w-8 place-items-center rounded-full text-navy-400 hover:bg-navy-50"
            onClick={onCancel}
            aria-label="Close"
          >
            <X size={16} />
          </button>
        </div>

        <h3 className="mt-4 text-[18px] font-bold text-navy-900">{title}</h3>
        <p className="mt-2 text-[14.5px] leading-relaxed text-navy-400">
          {description}
        </p>

        <div className="mt-7 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button
            onClick={onCancel}
            disabled={loading}
            className="rounded-full border border-navy-100 px-5 py-2.5 text-[14.5px] font-semibold text-navy-700 hover:bg-navy-50 disabled:opacity-50"
          >
            {cancelLabel}
          </button>
          <button
            onClick={onConfirm}
            disabled={loading}
            className={`rounded-full px-5 py-2.5 text-[14.5px] font-semibold text-white transition-colors disabled:opacity-60 ${
              danger
                ? 'bg-red-600 hover:bg-red-700'
                : 'bg-brand-500 hover:bg-brand-600'
            }`}
          >
            {loading ? 'Please wait…' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  )
}
