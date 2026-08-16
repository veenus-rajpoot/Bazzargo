import { useState } from 'react'
import { ChevronDown } from 'lucide-react'

export default function FaqAccordion({ items, defaultOpenIndex = 0 }) {
  const [openIndex, setOpenIndex] = useState(defaultOpenIndex)

  return (
    <div className="divide-y divide-navy-100 rounded-2xl border border-navy-100 bg-white">
      {items.map((item, i) => {
        const isOpen = openIndex === i
        return (
          <div key={item.q}>
            <button
              className="flex w-full items-center justify-between gap-4 px-6 py-5 text-left"
              onClick={() => setOpenIndex(isOpen ? -1 : i)}
              aria-expanded={isOpen}
            >
              <span className="text-[15.5px] font-semibold text-navy-900">
                {item.q}
              </span>
              <ChevronDown
                size={18}
                className={`shrink-0 text-navy-400 transition-transform duration-200 ${
                  isOpen ? 'rotate-180 text-brand-500' : ''
                }`}
              />
            </button>
            <div
              className={`grid transition-all duration-200 ease-in-out ${
                isOpen ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'
              }`}
            >
              <div className="overflow-hidden">
                <p className="px-6 pb-5 text-[14.5px] leading-relaxed text-navy-400">
                  {item.a}
                </p>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
